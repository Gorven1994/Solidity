// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Define a custom interface for deposit and withdrawal
interface ITokenHandler {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// Uniswap interface for swapping tokens
interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SushiSwap interface for swapping tokens
interface ISushiSwapRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract FlashLoan is ITokenHandler {
    address public owner;
    mapping(address => uint256) public balances; // Tracks user balances

    constructor() {
        owner = msg.sender;
    }

    // Deposit ETH into the contract
    function deposit() external payable override {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
    }

    // Withdraw ETH from the contract
    function withdraw(uint256 amount) external override {
        require(amount > 0, "Withdraw amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    // Fetch token price from Uniswap
function getUniswapTokenPrice(
    address router,
    uint256 amountIn,
    address[] calldata path
) external view returns (uint256[] memory amounts) {
    return IUniswapV2Router(router).getAmountsOut(amountIn, path);
}

// Fetch token price from SushiSwap
function getSushiSwapTokenPrice(
    address router,
    uint256 amountIn,
    address[] calldata path
) external view returns (uint256[] memory amounts) {
    return ISushiSwapRouter(router).getAmountsOut(amountIn, path);
}

// Swap tokens on Uniswap with slippage protection
function swapTokensOnUniswapWithSlippage(
    address router,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline,
    uint256 slippage // Maximum allowed slippage in percentage (e.g., 1 for 1%)
) external {
    uint256[] memory amounts = IUniswapV2Router(router).getAmountsOut(amountIn, path);
    uint256 expectedOut = amounts[amounts.length - 1];
    uint256 minOutWithSlippage = (expectedOut * (100 - slippage)) / 100;
    require(amountOutMin >= minOutWithSlippage, "Unacceptable slippage");

    IUniswapV2Router(router).swapExactTokensForTokens(amountIn, minOutWithSlippage, path, to, deadline);
}

// Swap tokens on SushiSwap with slippage protection
function swapTokensOnSushiSwapWithSlippage(
    address router,
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline,
    uint256 slippage 
    
    // Maximum allowed slippage in percentage (e.g., 1 for 1%)
) external {
    uint256[] memory amounts = ISushiSwapRouter(router).getAmountsOut(amountIn, path);
    uint256 expectedOut = amounts[amounts.length - 1];
    uint256 minOutWithSlippage = (expectedOut * (100 - slippage)) / 100;
    require(amountOutMin >= minOutWithSlippage, "Unacceptable slippage");

    ISushiSwapRouter(router).swapExactTokensForTokens(amountIn, minOutWithSlippage, path, to, deadline);
}

// Swap tokens on Uniswap
    function swapTokensOnUniswap(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        IUniswapV2Router(router).swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
    }

    // Swap tokens on SushiSwap
    function swapTokensOnSushiSwap(
        address router,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        ISushiSwapRouter(router).swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
    }

    // Flash loan function
    function executeFlashLoan(uint256 loanAmount, address loanReceiver) external {
        require(address(this).balance >= loanAmount, "Insufficient contract balance");

        // Record balance before loan
        uint256 balanceBefore = address(this).balance;

        // Send loan to the receiver
        (bool success, ) = loanReceiver.call{value: loanAmount}("");
        require(success, "Flash loan failed");

        // Ensure the funds are repaid
        require(address(this).balance >= balanceBefore, "Flash loan not repaid");
    }

    // Fallback function to accept ETH deposits
    receive() external payable {}
}
