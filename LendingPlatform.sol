// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LendingPlatform {
    address public owner;
    uint256 public interestRate;
    uint256 public depositInterst;
    uint256 public time;
    uint256 public start;
    mapping(address => uint256) private totalDeposit;  //Total balance
    mapping(address => uint256) private debts;         //Total debt
    mapping(address => uint256) private depositIncome; //Incentive for people to deposit
    

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrow(address indexed user, uint256 amount);
    event Repay(address indexed user, uint256 amount);

    constructor (uint256 _interestRate, uint256 _timeInSec, uint256 _depositIneterst){
        owner = msg.sender;
        interestRate = _interestRate;
        time = _timeInSec;
        depositInterst = _depositIneterst;
    }

    //Deposit to the platform
    function deposit() public payable {
        updateDebt(msg.sender);
        require(msg.value > 0, "Deposit amount must be greater than 0");
        totalDeposit[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    //Withdrawing from the platform
    function withdraw(uint256 amount) public {
        updateDebt(msg.sender);
        require(amount <= totalDeposit[msg.sender], "Insufficient balance");
        totalDeposit[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    //Borrowing from the platform
    function borrow(uint256 amount) external {
        start = block.timestamp;
        updateDebt(msg.sender);
        require(amount <= totalDeposit[msg.sender], "Insufficient balance");
        totalDeposit[msg.sender] -= amount;
        debts[msg.sender] += amount;
        payable(msg.sender).transfer(amount);
   
        emit Borrow(msg.sender, amount);
    }

    //Repaying the debt amount
    function repay() public payable {
        updateDebt(msg.sender);
        require(msg.value <= debts[msg.sender], "Repayment amount exceeds debt");
        debts[msg.sender] -= msg.value;
        totalDeposit[address(this)] += msg.value;
        emit Repay(msg.sender, msg.value);
    }


    function checkBalance() public returns (uint256 balance, uint256 debt, uint256 income) {
        updateDebt(msg.sender); //Had to updateDebt before returning value, hence had to remove view
        return (totalDeposit[msg.sender], debts[msg.sender], depositIncome[msg.sender]);
    }

    // Internal function to update debt based on time and interest rate
    function updateDebt(address user) internal {
        if (block.timestamp >= start + time) {
            uint256 timeCompleted = block.timestamp - start;
            uint256 interest = (debts[user] * interestRate * timeCompleted) / (100 * 365 days);
            depositIncome[user] = (totalDeposit[user] * depositInterst * timeCompleted)/(100*365 days);
            debts[user] += interest;
            totalDeposit[user] += depositIncome[user];
            
            start = block.timestamp;  // Reset the start time after applying interest
        }
    } //Can find better alternatives as to how to apply the interest rate as it is a bit more complicated.
}