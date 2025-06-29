// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title ISwapRouter
 * @notice Interface for token swapping functionality in the protocol
 * @dev This interface provides access to DEX functionality (likely Uniswap V3) for
 *      swapping tokens within the protocol, particularly for yield harvesting and
 *      debt management operations. It supports both exact input and exact output swaps.
 */
interface ISwapRouter {
    /**
     * @notice Parameters for exact input single-hop swaps
     * @dev Struct containing all parameters needed to perform a swap with a known input amount
     */
    struct ExactInputSingleParams {
        address tokenIn; /// @dev The address of the input token
        address tokenOut; /// @dev The address of the output token
        uint24 fee; /// @dev The fee tier of the pool (e.g., 500, 3000, 10000)
        address recipient; /// @dev The address to receive the output tokens
        uint256 deadline; /// @dev The unix timestamp after which the swap will revert
        uint256 amountIn; /// @dev The exact amount of input tokens to swap
        uint256 amountOutMinimum; /// @dev The minimum amount of output tokens to receive
        uint160 sqrtPriceLimitX96; /// @dev The price limit for the swap (0 = no limit)
    }

    /**
     * @notice Parameters for exact output single-hop swaps
     * @dev Struct containing all parameters needed to perform a swap with a known output amount
     */
    struct ExactOutputSingleParams {
        address tokenIn; /// @dev The address of the input token
        address tokenOut; /// @dev The address of the output token
        uint24 fee; /// @dev The fee tier of the pool (e.g., 500, 3000, 10000)
        address recipient; /// @dev The address to receive the output tokens
        uint256 deadline; /// @dev The unix timestamp after which the swap will revert
        uint256 amountOut; /// @dev The exact amount of output tokens to receive
        uint256 amountInMaximum; /// @dev The maximum amount of input tokens to spend
        uint160 sqrtPriceLimitX96; /// @dev The price limit for the swap (0 = no limit)
    }

    /**
     * @notice Swaps exact amount of input tokens for as much output as possible
     * @dev Executes a single-hop swap where the input amount is known and output is maximized.
     *      Used for harvesting yield tokens and converting them to desired assets.
     * @param params The swap parameters encoded as ExactInputSingleParams
     * @return amountOut The amount of output tokens received from the swap
     */
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    /**
     * @notice Swaps minimum input tokens for exact amount of output tokens
     * @dev Executes a single-hop swap where the output amount is known and input is minimized.
     *      Used when a specific amount of tokens is needed (e.g., for debt repayment).
     * @param params The swap parameters encoded as ExactOutputSingleParams
     * @return amountIn The amount of input tokens consumed in the swap
     */
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    /**
     * @notice Calculates the expected output amount for a given input
     * @dev Provides a quote for how many output tokens would be received for a given input.
     *      Used for calculating expected yields and swap previews without executing the swap.
     * @param tokenIn The address of the input token
     * @param tokenOut The address of the output token
     * @param fee The fee tier of the pool to use for the swap
     * @param amountIn The amount of input tokens to quote
     * @return amountOut The expected amount of output tokens
     */
    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) external view returns (uint256 amountOut);
}
