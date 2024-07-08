// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DEX Template
 * @notice A simple decentralized exchange for ETH and ERC20 tokens
 */
contract DEX {
    /* ========== GLOBAL VARIABLES ========== */

    IERC20 public token; // ERC20 token interface
    uint256 public totalLiquidity; // Total liquidity in the DEX
    mapping(address => uint256) public liquidity; // Liquidity of each provider

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap(
        address indexed swapper,
        uint256 tokenOutput,
        uint256 ethInput
    );

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap(
        address indexed swapper,
        uint256 tokensInput,
        uint256 ethOutput
    );

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    event LiquidityProvided(
        address indexed liquidityProvider,
        uint256 liquidityMinted,
        uint256 ethInput,
        uint256 tokensInput
    );

    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    event LiquidityRemoved(
        address indexed liquidityRemover,
        uint256 liquidityWithdrawn,
        uint256 tokensOutput,
        uint256 ethOutput
    );

    /* ========== CONSTRUCTOR ========== */

    constructor(address token_addr) {
        token = IERC20(token_addr); // Initialize the token interface
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Initializes the DEX with ETH and token reserves
     * @param tokens Amount of tokens to be transferred to the DEX
     * @return totalLiquidity The total liquidity provided to the DEX
     */
    function init(uint256 tokens) public payable returns (uint256) {
        require(totalLiquidity == 0, "DEX: already initialized");
        totalLiquidity = address(this).balance;
        liquidity[msg.sender] = totalLiquidity;
        require(token.transferFrom(msg.sender, address(this), tokens), "DEX: token transfer failed");
        emit LiquidityProvided(msg.sender, totalLiquidity, msg.value, tokens);
        return totalLiquidity;
    }

    /**
     * @notice Calculates the output amount of y for a given input amount of x
     * @param xInput Amount of x being input
     * @param xReserves Current x reserves in the DEX
     * @param yReserves Current y reserves in the DEX
     * @return yOutput Amount of y to be output
     */
    function price(uint256 xInput, uint256 xReserves, uint256 yReserves) public pure returns (uint256 yOutput) {
        uint256 xInputWithFee = xInput * 997;
        uint256 numerator = xInputWithFee * yReserves;
        uint256 denominator = (xReserves * 1000) + xInputWithFee;
        return numerator / denominator;
    }

    /**
     * @notice Returns the liquidity of a given user
     * @param lp Address of the liquidity provider
     * @return The liquidity of the user
     */
    function getLiquidity(address lp) public view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice Swaps ETH for tokens
     * @return tokenOutput Amount of tokens received from the swap
     */
    function ethToToken() public payable returns (uint256 tokenOutput) {
        require(msg.value > 0, "DEX: zero ETH sent");
        uint256 ethInput = msg.value;
        uint256 ethReserves = address(this).balance - ethInput;
        uint256 tokenReserves = token.balanceOf(address(this));
        tokenOutput = price(ethInput, ethReserves, tokenReserves);
        require(token.transfer(msg.sender, tokenOutput), "DEX: token transfer failed");
        emit EthToTokenSwap(msg.sender, tokenOutput, ethInput);
        return tokenOutput;
    }

    /**
     * @notice Swaps tokens for ETH
     * @param tokenInput Amount of tokens to be swapped
     * @return ethOutput Amount of ETH received from the swap
     */
    function tokenToEth(uint256 tokenInput) public returns (uint256 ethOutput) {
        require(tokenInput > 0, "DEX: zero tokens sent");
        uint256 ethReserves = address(this).balance;
        uint256 tokenReserves = token.balanceOf(address(this));
        ethOutput = price(tokenInput, tokenReserves, ethReserves);
        require(token.transferFrom(msg.sender, address(this), tokenInput), "DEX: token transfer failed");
        (bool success, ) = msg.sender.call{value: ethOutput}("");
        require(success, "DEX: ETH transfer failed");
        emit TokenToEthSwap(msg.sender, tokenInput, ethOutput);
        return ethOutput;
    }

    /**
     * @notice Allows users to deposit ETH and tokens into the liquidity pool
     * @return tokensDeposited Amount of tokens deposited
     */
    function deposit() public payable returns (uint256 tokensDeposited) {
        require(msg.value > 0, "DEX: zero ETH deposited");
        uint256 ethReserves = address(this).balance - msg.value;
        uint256 tokenReserves = token.balanceOf(address(this));
        uint256 tokenAmount = (msg.value * tokenReserves) / ethReserves;
        require(token.transferFrom(msg.sender, address(this), tokenAmount), "DEX: token transfer failed");
        uint256 liquidityMinted = (msg.value * totalLiquidity) / ethReserves;
        liquidity[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;
        emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, tokenAmount);
        return tokenAmount;
    }

    /**
     * @notice Allows users to withdraw ETH and tokens from the liquidity pool
     * @param amount Amount of liquidity to withdraw
     * @return ethAmount Amount of ETH withdrawn
     * @return tokenAmount Amount of tokens withdrawn
     */
    function withdraw(uint256 amount) public returns (uint256 ethAmount, uint256 tokenAmount) {
        require(liquidity[msg.sender] >= amount, "DEX: insufficient liquidity");
        uint256 ethReserves = address(this).balance;
        uint256 tokenReserves = token.balanceOf(address(this));
        ethAmount = (amount * ethReserves) / totalLiquidity;
        tokenAmount = (amount * tokenReserves) / totalLiquidity;
        liquidity[msg.sender] -= amount;
        totalLiquidity -= amount;
        (bool success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "DEX: ETH transfer failed");
        require(token.transfer(msg.sender, tokenAmount), "DEX: token transfer failed");
        emit LiquidityRemoved(msg.sender, amount, tokenAmount, ethAmount);
    }
}