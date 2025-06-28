// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IsAVAX {
    // Submit to stake AVAX and receive sAVAX
    function submit() external payable returns (uint256);

    // Withdraw to burn sAVAX and receive native AVAX
    function withdraw(uint256 amount) external returns (uint256);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalShares() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _user) external view returns (uint256);

    function transferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    function transfer(
        address _recipient,
        uint256 _amount
    ) external returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool);
}
