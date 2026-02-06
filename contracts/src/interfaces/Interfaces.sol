// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC20 Interface
 * @notice Standard interface for ERC20 tokens
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/**
 * @title INToken Interface
 * @notice Interface for NexusLend's interest-bearing tokens
 */
interface INToken {
    function mint(
        address user,
        uint256 underlyingAmount
    ) external returns (uint256);
    function burn(
        address user,
        uint256 nTokenAmount
    ) external returns (uint256);
    function balanceOfUnderlying(address user) external view returns (uint256);
    function exchangeRate() external view returns (uint256);
    function updateExchangeRate(uint256 newRate) external;
}

/**
 * @title IInterestRateModel Interface
 * @notice Interface for interest rate calculations
 */
interface IInterestRateModel {
    function getBorrowRate(
        uint256 totalBorrows,
        uint256 totalLiquidity
    ) external view returns (uint256);
    function getSupplyRate(
        uint256 totalBorrows,
        uint256 totalLiquidity,
        uint256 reserveFactor
    ) external view returns (uint256);
    function getUtilizationRate(
        uint256 totalBorrows,
        uint256 totalLiquidity
    ) external pure returns (uint256);
}

/**
 * @title IPriceOracle Interface
 * @notice Interface for price feeds
 */
interface IPriceOracle {
    function getPrice(address asset) external view returns (uint256);
}
