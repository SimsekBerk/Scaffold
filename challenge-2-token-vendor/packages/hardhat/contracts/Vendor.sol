pragma solidity 0.8.4; //Do not change the solidity version as it negativly impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
  YourToken public yourToken;
  uint256 public constant tokensPerEth = 100;

  // Event to emit when tokens are bought
  event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
  event SellTokens(address seller, uint256 amountOfTokens, uint256 amountOfETH);


  constructor(address tokenAddress) Ownable() {
    yourToken = YourToken(tokenAddress);
  }

  // ToDo: create a payable buyTokens() function:
  function buyTokens() public payable {
        uint256 tokenAmount = msg.value * tokensPerEth;
        yourToken.transfer(msg.sender, tokenAmount);

        emit BuyTokens(msg.sender, msg.value, tokenAmount);
    }


  // ToDo: create a withdraw() function that lets the owner withdraw ETH
  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    (bool sent, ) = payable(msg.sender).call{value: balance}("");
    require(sent, "Failed to send Ether");
  }

  // ToDo: create a sellTokens(uint256 _amount) function:
  function sellTokens(uint256 amount) public {
    uint256 etherAmount = amount / tokensPerEth;
    require(address(this).balance >= etherAmount, "Vendor: not enough ETH");

    // Transfer tokens from the user to this contract
    require(yourToken.transferFrom(msg.sender, address(this), amount), "Failed to transfer tokens");

    // Send Ether to the user
    (bool sent, ) = msg.sender.call{value: etherAmount}("");
    require(sent, "Failed to send Ether");

    emit SellTokens(msg.sender, amount, etherAmount);
  }
}