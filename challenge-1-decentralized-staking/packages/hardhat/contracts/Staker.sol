// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  mapping(address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 60 seconds;
  bool public openForWithdrawal = false;

  event Stake(address indexed sender, uint256 amount);

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Stake function to collect and track funds
  function stake() public payable {
      require(block.timestamp < deadline, "Staking period has ended");
      require(msg.value > 0, "Cannot stake 0 ETH");

      balances[msg.sender] += msg.value;
      emit Stake(msg.sender, msg.value);
  }

  // Execute function to interact with external contract
  function execute() public {
    require(block.timestamp >= deadline, "Condition not met");
    if (address(this).balance >= threshold) {
    exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdrawal = true;
    }
  }

  // Withdraw function to allow stakers to withdraw their funds if the threshold is not met
  function withdraw() public {
      require(block.timestamp >= deadline, "Deadline has not yet been reached");
      require(openForWithdrawal == true, "Threshold has not been met");
      uint256 balance = balances[msg.sender];
      require(balance > 0, "No funds to withdraw");

      balances[msg.sender] = 0;
      (bool sent, ) = msg.sender.call{value: balance}("");
      require(sent, "Failed to send Ether");
  }

  // Time left for staking
  function timeLeft() public view returns (uint256) {
      if (block.timestamp >= deadline) {
          return 0;
      } else {
          return deadline - block.timestamp;
      }
  }

  // Receive function to handle direct ETH sends
  receive() external payable {
      stake();
  }
}