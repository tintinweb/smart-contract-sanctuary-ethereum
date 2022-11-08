# @version ^0.3.0

interface ERC20:

    def transfer(receiver: address, val: uint256) -> bool: nonpayable


    def transferFrom(owner: address, spender: address, val: uint256) -> bool: nonpayable


    def balanceOf(arg0: address) -> uint256: view


tokenAddress: public(address)

struct UserDeposit:
    depositAmount: uint256
    endTime: uint256

lockTime: public(uint256)
owner: public(address)
userDeposits: public(HashMap[address, UserDeposit])
totalReward: public(uint256)
currentReward: public(uint256)
totalStaked: public(uint256)
currentStaked: public(uint256)
interestRate: public(uint256)

event Staked :
    user: indexed(address)
    amount: indexed(uint256)
    time: uint256

event RewardsAdded :
    amount: uint256
    time: uint256

event Withdrawn :
    user: indexed(address)
    amount: indexed(uint256)
    time: uint256

@external
def __init__(_locktime: uint256, _tokenAddress: address, _interestRate: uint256) :
    assert _tokenAddress != empty(address), "Zero token address"
    assert _locktime > 0, "Zero lock time"
    assert _interestRate > 0, "Zero interest rate"
    self.lockTime = _locktime
    self.owner = msg.sender
    self.tokenAddress = _tokenAddress
    self.interestRate = _interestRate


@external
def addReward(_rewardAmount: uint256) :
    assert _rewardAmount > 0, "Adding zero rewards"
    self.totalReward += _rewardAmount
    self.currentReward += _rewardAmount
    status: bool = ERC20(self.tokenAddress).transferFrom(msg.sender, self, _rewardAmount)
    assert status == True, "Transfer from failed"
    log RewardsAdded(_rewardAmount, block.timestamp)

@external
def stake(_depositAmount: uint256) -> bool :
    assert _depositAmount > 0, "Zero deposit amount"
    user: UserDeposit = self.userDeposits[msg.sender]
    assert user.depositAmount == 0, "Already deposited"
    user = UserDeposit({
                depositAmount: _depositAmount, 
                endTime: block.timestamp + self.lockTime
            })
    self.userDeposits[msg.sender] = user
    self.totalStaked += _depositAmount
    self.currentStaked += _depositAmount
    status: bool = ERC20(self.tokenAddress).transferFrom(msg.sender, self, _depositAmount)
    assert status == True, "Transfer from failed"
    log Staked(msg.sender, _depositAmount, block.timestamp)
    return True


@external
def withdraw() -> bool :
    user: UserDeposit = self.userDeposits[msg.sender]
    rewards: uint256 = self._calculate(msg.sender)
    assert user.endTime <= block.timestamp, "End time not reached"
    assert rewards > self.currentReward, "Not enough rewards in the contract"
    self.currentReward -= rewards
    self.currentStaked -= user.depositAmount
    self.userDeposits[msg.sender] = empty(UserDeposit)
    status: bool = ERC20(self.tokenAddress).transfer(msg.sender, user.depositAmount + rewards)
    assert status == True, "Transfer failed"
    log Withdrawn(msg.sender, user.depositAmount + rewards, block.timestamp)
    return True


@view
@internal
def _calculate(_user: address) -> uint256 :
    user: UserDeposit = self.userDeposits[_user]
    assert user.depositAmount > 0, "No deposits"
    amount: uint256 = (user.depositAmount * self.interestRate) / 10000
    return amount

@view
@external
def calculate(_user: address) -> uint256 :
    return self._calculate(_user)


@external
def emergencyWithdraw() -> bool :
    user: UserDeposit = self.userDeposits[msg.sender]
    assert user.endTime <= block.timestamp, "End time not reached"
    self.currentStaked -= user.depositAmount
    self.userDeposits[msg.sender] = empty(UserDeposit)
    status: bool = ERC20(self.tokenAddress).transfer(msg.sender, user.depositAmount )
    assert status == True, "Transfer failed"
    log Withdrawn(msg.sender, user.depositAmount, block.timestamp)
    return True