// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}






contract Wallet {
    address public owner; // Адрес владельца контракта
    IERC20 public token;

    struct User {
        uint256 targetAmount; 
        uint256 intervalEndTime; 
        uint256 totalDeposits; 
        uint256 interval;
        uint256 depositAmount;
    }

    mapping(address => User) public users;

    event Deposit(address indexed user);
    event TokensTransferredToOwner(address indexed user, uint256 amount);
    event TokensReturnedToUser(address indexed user, uint256 amount);
    event UserInitialized(address indexed user, uint256 targetAmount, uint256 interval, uint256 depositAmount);

    constructor(address _tokenAddress) {
        owner = msg.sender; 
        token = IERC20(_tokenAddress);
    }   


    function start(uint256 amount, uint256 _targetAmount, uint256 _interval ) public {
        User storage user = users[msg.sender];
        uint256 currentTime = block.timestamp;
        if(user.intervalEndTime < currentTime && user.intervalEndTime != 0 && user.targetAmount > user.totalDeposits){
            lose(msg.sender);
        }

        require(amount != 0 && _targetAmount != 0 && _interval != 0, "not 0");    
        require(amount < _targetAmount, "Target amount must be higher than deposit amount.");
        require(token.transferFrom(msg.sender, address(this), amount), "Initial token transfer failed.");

        user.targetAmount = _targetAmount;
        user.interval = _interval;
        user.totalDeposits = amount;
        user.depositAmount = amount;
        user.intervalEndTime = block.timestamp + _interval + _interval;
        emit UserInitialized(msg.sender, _targetAmount, _interval, amount);

    }


    function lose(address loser) public {
        uint256 currentTime = block.timestamp;
        User storage user = users[loser];
        require(currentTime > user.intervalEndTime && user.intervalEndTime != 0, "user not late");
        require(token.balanceOf(address(this)) >= user.totalDeposits, "Not enough tokens in contract");
        require(token.transfer(owner, user.totalDeposits), "Transfer to owner failed.");
        emit TokensTransferredToOwner(loser, user.totalDeposits);

        user.targetAmount = 0;
        user.interval = 0;
        user.totalDeposits = 0;
        user.intervalEndTime = 0;
        user.depositAmount = 0;

        return;

    }
 function deposit() public {
    User storage user = users[msg.sender];
    uint256 currentTime = block.timestamp;

    require(user.intervalEndTime > currentTime || user.totalDeposits < user.targetAmount, "You must initial contract.");
    require(currentTime > user.intervalEndTime - user.interval, "You cannot deposit before interval time.");



    require(token.transferFrom(msg.sender, address(this), user.depositAmount), "Token transfer failed.");

    user.totalDeposits += user.depositAmount;



    // Если достигли цели — возвращаем сумму пользователю и сбрасываем данные
    if (user.totalDeposits >= user.targetAmount) {
        require(token.balanceOf(address(this)) >= user.totalDeposits, "Not enough tokens in contract");
        require(token.transfer(msg.sender, user.totalDeposits), "Return tokens failed.");
        user.intervalEndTime = currentTime;
        emit TokensReturnedToUser(msg.sender, user.totalDeposits);

    }else{
        user.intervalEndTime += user.interval;
        emit Deposit(msg.sender);

    }
   

}
    function getContractTokenBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getUserInfo(address userAddress) external view returns (uint256 targetAmount, uint256 intervalEndTime, uint256 totalDeposits, uint256 interval, uint256 depositAmount) {
        User storage user = users[userAddress];
        return (user.targetAmount, user.intervalEndTime, user.totalDeposits, user.interval, user.depositAmount);
    }

    receive() external payable {
    revert("Contract does not accept ETH");
    }

    fallback() external payable {
        revert("Contract does not accept ETH");
    }
}