// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Mock contracts for testing
contract MockChainlinkOracleManager {
    mapping(address => uint256) public prices;

    function getAssetPrice(address asset) external view returns (uint256) {
        return prices[asset];
    }

    function setAssetPrice(address asset, uint256 price) external {
        prices[asset] = price;
    }
}

contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
}

contract MockPriorityPool {
    function deposit(uint256 amount, bool shouldQueue, bytes[] calldata data) external {}

    function withdraw(
        uint256 amount,
        uint256 amountOut,
        uint256 sharesOut,
        bytes32[] calldata proof,
        bool shouldUnqueue,
        bool shouldQueueWithdrawal,
        bytes[] calldata data
    ) external {}
}

contract MockWithdrawalQueue {
    function requestWithdrawals(uint256[] calldata amounts, address owner) external returns (uint256[] memory) {
        uint256[] memory requestIds = new uint256[](amounts.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            requestIds[i] = i + 1;
        }
        return requestIds;
    }

    function claimWithdrawal(uint256 requestId) external {}
}

contract MockWETH {
    function deposit() external payable {}

    function withdraw(uint256 amount) external {}

    function approve(address spender, uint256 amount) external returns (bool) {
        return true;
    }
}

contract MockMorphoVault {
    address public immutable asset;

    constructor(address _asset) {
        asset = _asset;
    }

    function deposit(uint256 assets, address receiver) external returns (uint256) {
        return assets; // 1:1 for simplicity
    }

    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256) {
        return assets;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        return true;
    }
}

contract MockRETH {
    function getRethValue(uint256 ethAmount) external pure returns (uint256) {
        return (ethAmount * 95) / 100; // Simplified exchange rate
    }

    function getEthValue(uint256 rethAmount) external pure returns (uint256) {
        return (rethAmount * 100) / 95; // Inverse of above
    }

    function getExchangeRate() external pure returns (uint256) {
        return 1050000000000000000; // 1.05 ETH per rETH
    }

    function burn(uint256 amount) external {}

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        return true;
    }
}

contract MockRocketDepositPool {
    function deposit() external payable {}
}

contract MockRocketDAOSettings {
    function getDepositFee() external pure returns (uint256) {
        return 5000000000000000; // 0.5%
    }
}
