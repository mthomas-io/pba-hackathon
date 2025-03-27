// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "hardhat/console.sol";

/**
 * @title Owner
 * @dev Set & change owner
 */
contract StakeHouse {
    address public owner; // Anyone can see who owns this contract
    uint public nextRewardTime;
    uint public rewardInterval = 7 days;

    address[] private users;
    mapping(address => uint) private balances;
    uint public totalDeposits;

    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event BonusRewarded(address indexed winner, uint prize);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor(uint _interval) {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
        rewardInterval = _interval;
        nextRewardTime = block.timestamp + _interval;
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        require(msg.value > 0, "Send DOT to contribute to savings");

        if (balances[msg.sender] == 0) {
            users.push(msg.sender);
        }

        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;

        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() public {
        uint amount = balances[msg.sender];
        require(amount > 0, "No savings to withdraw");

        balances[msg.sender] = 0;
        totalDeposits -= amount;
        payable(msg.sender).transfer(amount);

        emit Withdrawn(msg.sender, amount);
    }

    function distributeBonus() public isOwner {
        require(block.timestamp >= nextRewardTime, "Too early to distribute bonus");
        require(users.length > 0, "No users yet");

        // 🚨 WARNING: Pseudo-randomness - not secure, just for dev/demo
        uint rand = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % users.length;
        address selectedUser = users[rand];

        uint bonus = address(this).balance - totalDeposits;
        require(bonus > 0, "No bonus to distribute");

        nextRewardTime = block.timestamp + rewardInterval;
        payable(selectedUser).transfer(bonus);

        emit BonusRewarded(selectedUser, bonus);
    }


    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        require(newOwner != address(0), "New owner should not be the zero address");
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
} 
