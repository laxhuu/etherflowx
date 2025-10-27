// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title EtherFlowX
 * @dev A smart contract that enables users to deposit, withdraw, and check balances in Ether.
 */
contract EtherFlowX {
    mapping(address => uint256) private balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    /**
     * @dev Deposit Ether into the contract.
     */
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Withdraw Ether from the contract.
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev Get the Ether balance of a user.
     */
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }
}
