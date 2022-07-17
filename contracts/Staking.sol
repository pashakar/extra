// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 @title A contract for staking
 */
contract Staking {
    // variable for keep track of staking balance
    uint256 public allBalanceStaking;

    // 10000 == 100%
    uint256 internal constant percents = 10000;

    // onwer of contract
    address public owner;

    struct Deposit {
        uint256 amount;
        uint256 startTime;
        uint256 duration;
    }
    // Mapping owner deposit to deposit
    mapping(address => Deposit) private _addrToDeposit;

    // mapping from deposit duration in minutes to reward percent
    mapping(uint256 => uint256) public minutesToPercent;

    event DepositCreate(address depositor, uint256 amount, uint256 duration);
    event DepositWithdraw(address depositor, uint256 allAmount);

    /**
     @dev initializes contract with default settings: 3, 5 and 10 min
     */
    constructor(
        uint256 _stakingReward3Minutes,
        uint256 _stakingReward5Minutes,
        uint256 _stakingReward10Minutes
    ) {
        owner = msg.sender;
        minutesToPercent[3] = _stakingReward3Minutes;
        minutesToPercent[5] = _stakingReward5Minutes;
        minutesToPercent[10] = _stakingReward10Minutes;
    }

    /**
     @dev change settings
     @param _minutes new deposit duration or change prev
     @param _stakingReward new deposit reward. If is 0 then deposit duration is not active
     */
    function setParams(uint256 _minutes, uint256 _stakingReward) external {
        require(msg.sender == owner, "!owner");
        require(_minutes != 0, "!minutes");
        minutesToPercent[_minutes] = _stakingReward;
    }

    /**
     @dev get info about deposit
     @param _addr owner deposit
     */
    function getDepositInfo(address _addr)
        external
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        require(_addr != address(0), "!address");
        Deposit memory deposit = _addrToDeposit[_addr];
        return (_addr, deposit.startTime, deposit.startTime + deposit.duration);
    }

    /**
     @dev create deposit
     @param _duration deposit in minute
     */
    function createDeposit(uint256 _duration) external payable {
        require(minutesToPercent[_duration] != 0, "!rate");
        require(msg.value != 0, "!amount");
        uint256 duration = _duration * 1 minutes;
        Deposit memory deposit = Deposit(msg.value, block.timestamp, duration);
        _addrToDeposit[msg.sender] = deposit;
        allBalanceStaking += msg.value;
        emit DepositCreate(msg.sender, msg.value, _duration);
    }

    /**
     @dev withdraw deposit
     */
    function withdrawDeposit() external {
        Deposit memory deposit = _addrToDeposit[msg.sender];
        require(deposit.amount != 0, "!deposit");
        bool periodIsReached = (block.timestamp - deposit.startTime) >=
            deposit.duration;
        require(periodIsReached, "!period");
        uint256 rewardsPercent = minutesToPercent[deposit.duration / 1 minutes];
        uint256 rewardsAmount = deposit.amount +
            (deposit.amount * rewardsPercent) /
            percents;
        rewardsAmount = rewardsAmount > address(this).balance
            ? address(this).balance
            : rewardsAmount;
        (bool success, ) = msg.sender.call{value: rewardsAmount}("");
        require(success, "!send");
        allBalanceStaking -= rewardsAmount;
        _addrToDeposit[msg.sender] = Deposit(0, 0, 0);
        emit DepositWithdraw(msg.sender, rewardsAmount);
    }
}
