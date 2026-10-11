// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract ChainFour {
    uint8 public constant WIDTH = 7;
    uint8 public constant HEIGHT = 6;
    uint256 public constant TIMEOUT = 3 days;

    enum Status { Waiting, Active, Player1Won, Player2Won, Draw, TimeoutPlayer1Won, TimeoutPlayer2Won }

    struct Game {
        address player1;
        address player2;
        uint8[42] board; // 0 empty, 1 player1, 2 player2
        uint8 turn;      // 1 or 2
        Status status;
        uint64 lastMoveAt;
        address winner;
        uint8 moveCount;
    }

    uint256 public nextGameId = 1;
    mapping(uint256 => Game) private games;

    event GameCreated(uint256 indexed gameId, address indexed player1);
    event PlayerJoined(uint256 indexed gameId, address indexed player2);
    event MoveMade(uint256 indexed gameId, address indexed player, uint8 column, uint8 row, uint8 piece);
    event GameFinished(uint256 indexed gameId, Status status, address winner);

    error UnknownGame();
    error WrongStatus();
    error NotPlayer();
    error NotYourTurn();
    error InvalidColumn();
    error ColumnFull();
    error TimeoutNotReached();
    error StallingPlayerCannotClaim();

    function createGame() external returns (uint256 gameId) {
        gameId = nextGameId++;
        Game storage g = games[gameId];
        g.player1 = msg.sender;
        g.turn = 1;
        g.status = Status.Waiting;
        g.lastMoveAt = uint64(block.timestamp);
        emit GameCreated(gameId, msg.sender);
    }

    function joinGame(uint256 gameId) external {
        Game storage g = _game(gameId);
        if (g.status != Status.Waiting) revert WrongStatus();
        if (msg.sender == g.player1) revert NotPlayer();
        g.player2 = msg.sender;
        g.status = Status.Active;
        g.lastMoveAt = uint64(block.timestamp);
        emit PlayerJoined(gameId, msg.sender);
    }

    function makeMove(uint256 gameId, uint8 column) external {
        Game storage g = _game(gameId);
        if (g.status != Status.Active) revert WrongStatus();
        if (msg.sender != g.player1 && msg.sender != g.player2) revert NotPlayer();
        address expected = g.turn == 1 ? g.player1 : g.player2;
        if (msg.sender != expected) revert NotYourTurn();
        if (column >= WIDTH) revert InvalidColumn();

        uint8 row = HEIGHT;
        for (uint8 r = 0; r < HEIGHT; r++) {
            if (g.board[uint256(r) * WIDTH + column] == 0) { row = r; break; }
        }
        if (row == HEIGHT) revert ColumnFull();

        g.board[uint256(row) * WIDTH + column] = g.turn;
        g.moveCount++;
        g.lastMoveAt = uint64(block.timestamp);
        emit MoveMade(gameId, msg.sender, column, row, g.turn);

        if (_isWinner(g, column, row, g.turn)) {
            g.winner = msg.sender;
            g.status = g.turn == 1 ? Status.Player1Won : Status.Player2Won;
            emit GameFinished(gameId, g.status, msg.sender);
        } else if (g.moveCount == WIDTH * HEIGHT) {
            g.status = Status.Draw;
            emit GameFinished(gameId, g.status, address(0));
        } else {
            g.turn = g.turn == 1 ? 2 : 1;
        }
    }

    function claimTimeout(uint256 gameId) external {
        Game storage g = _game(gameId);
        if (g.status != Status.Active) revert WrongStatus();
        if (block.timestamp <= uint256(g.lastMoveAt) + TIMEOUT) revert TimeoutNotReached();
        address stalling = g.turn == 1 ? g.player1 : g.player2;
        if (msg.sender == stalling) revert StallingPlayerCannotClaim();
        if (msg.sender != g.player1 && msg.sender != g.player2) revert NotPlayer();
        g.winner = msg.sender;
        g.status = msg.sender == g.player1 ? Status.TimeoutPlayer1Won : Status.TimeoutPlayer2Won;
        emit GameFinished(gameId, g.status, msg.sender);
    }

    function getGame(uint256 gameId) external view returns (
        address player1, address player2, uint8[42] memory board, uint8 turn,
        Status status, uint64 lastMoveAt, address winner, uint8 moveCount
    ) {
        Game storage g = _game(gameId);
        return (g.player1, g.player2, g.board, g.turn, g.status, g.lastMoveAt, g.winner, g.moveCount);
    }

    function _game(uint256 gameId) private view returns (Game storage g) {
        g = games[gameId];
        if (g.player1 == address(0)) revert UnknownGame();
    }

    function _isWinner(Game storage g, uint8 col, uint8 row, uint8 piece) private view returns (bool) {
        return _count(g, int256(uint256(col)), int256(uint256(row)), 1, 0, piece) >= 4
            || _count(g, int256(uint256(col)), int256(uint256(row)), 0, 1, piece) >= 4
            || _count(g, int256(uint256(col)), int256(uint256(row)), 1, 1, piece) >= 4
            || _count(g, int256(uint256(col)), int256(uint256(row)), 1, -1, piece) >= 4;
    }

    function _count(Game storage g, int256 x, int256 y, int256 dx, int256 dy, uint8 piece) private view returns (uint256 total) {
        total = 1;
        for (uint256 dir = 0; dir < 2; dir++) {
            int256 sx = dir == 0 ? dx : -dx;
            int256 sy = dir == 0 ? dy : -dy;
            int256 cx = x + sx;
            int256 cy = y + sy;
            while (cx >= 0 && cx < int256(uint256(WIDTH)) && cy >= 0 && cy < int256(uint256(HEIGHT))) {
                if (g.board[uint256(cy) * WIDTH + uint256(cx)] != piece) break;
                total++;
                cx += sx;
                cy += sy;
            }
        }
    }
}
