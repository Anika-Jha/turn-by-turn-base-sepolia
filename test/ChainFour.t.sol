// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "forge-std/Test.sol";
import "../src/ChainFour.sol";

contract ChainFourTest is Test {
    ChainFour game;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        game = new ChainFour();
        vm.warp(1_800_000_000);
    }

    function _newGame() internal returns (uint256 id) {
        vm.prank(alice); id = game.createGame();
        vm.prank(bob); game.joinGame(id);
    }

    function testCreateJoinAndMove() public {
        uint256 id = _newGame();
        vm.prank(alice); game.makeMove(id, 3);
        (,,,,,,, uint8 moves) = game.getGame(id);
        assertEq(moves, 1);
    }

    function testRejectWrongTurn() public {
        uint256 id = _newGame();
        vm.prank(bob); vm.expectRevert(ChainFour.NotYourTurn.selector); game.makeMove(id, 2);
    }

    function testRejectInvalidColumn() public {
        uint256 id = _newGame();
        vm.prank(alice); vm.expectRevert(ChainFour.InvalidColumn.selector); game.makeMove(id, 7);
    }

    function testMultipleGames() public {
        vm.prank(alice); uint256 a = game.createGame();
        vm.prank(bob); uint256 b = game.createGame();
        assertTrue(a != b);
    }

    function testTimeoutClaimByWaitingPlayer() public {
        uint256 id = _newGame();
        vm.prank(alice); game.makeMove(id, 0); // Bob is now on turn
        vm.warp(block.timestamp + game.TIMEOUT() + 1);
        vm.prank(alice); game.claimTimeout(id);
        (,,,, ChainFour.Status status,,, ) = game.getGame(id);
        assertEq(uint256(status), uint256(ChainFour.Status.TimeoutPlayer1Won));
    }

    function testStallingPlayerCannotClaimTimeout() public {
        uint256 id = _newGame();
        vm.warp(block.timestamp + game.TIMEOUT() + 1);
        vm.prank(alice); vm.expectRevert(ChainFour.StallingPlayerCannotClaim.selector); game.claimTimeout(id);
    }
}
