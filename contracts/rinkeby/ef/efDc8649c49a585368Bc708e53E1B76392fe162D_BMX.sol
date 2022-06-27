// SPDX-License-Identifier: MIT

/**
 * @title Smart contract for BMX token
 * @author Stenor Tanaka
 */
pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./Stakable.sol";

contract BMX is Ownable, Stakeable {
    /**
     * @notice Our Tokens required variables that are needed to operate everything
     */
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    uint256 private _publicSaleDate; /// @notice The date that the public sale started.
    uint256 private _tokenPrice;
    uint8 public restrictPercentage = 5; /// @notice Token holders can sell only 5% of their presaled Balances in a month.
    uint256 public maxSupply;
    bool public salePaused = false;

    /**
     * @notice _balances is a mapping that contains a address as KEY
     * and the balance of the address as the value
     */
    mapping(address => uint256) private _balances;

    /**
     * @notice _presaledBalances is a mapping that contains a address as KEY
     * and the transferable balance of the address as the value
     */
    mapping(address => uint256) private _presaledBalances;

    /**
     * @notice _allowances is used to manage and control allownace
     * An allowance is the right to use another accounts balance, or part of it
     */
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @notice Events are created below.
     * Transfer event is a event that notify the blockchain that a transfer of assets has taken place
     *
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
    /**
     * @notice Approval is emitted when a new Spender is approved to spend Tokens on
     * the Owners account
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @notice WithdrawStake is emittied when a user withdraw his staked tokens
     */
    event WithdrawStake(address indexed user, uint256 amount);

    /**
     * @notice BoughtToken are emitted when a user buy token
     * Admin account changed
     */
    event BoughtToken(address indexed user, uint256 amount);

    /**
     * @notice WithdrawStake is emittied when a user withdraw his staked tokens
     */
    event PublicSaleStarted(uint256 timeStamp, uint256 tokenPrice);

    /**
     * @notice Withdraw is emittied when the admin withdraw the fond from contract
     */
    event Withdraw(uint256 amount);

    /**
     * @notice This modifier is to restrict that the users can't transfer more than 5% of thier balance per month.
     */
    modifier restrictTransfer(address account, uint256 amount) {
        require(
            _balances[account] >= amount,
            "BMX: cant transfer more than your account owns"
        );
        if (account != owner()) {
            uint256 _transferableBalance = transferableToken(account);
            require(
                amount <= _transferableBalance,
                "BMX: Over 5% of your presale balance"
            );
        }
        _;
    }

    /**
     * @notice constructor will be triggered when we create the Smart contract
     * _name = name of the token
     * _short_symbol = Short Symbol name for the token
     * token_decimals = The decimal precision of the Token, defaults 18
     * _totalSupply is how much Tokens there are totally
     * _wastingFee is the fee of every transactions
     */
    constructor(
        string memory token_name,
        string memory short_symbol,
        uint8 token_decimals,
        uint256 token_maxSupply,
        uint256 token_price
    ) {
        _name = token_name;
        _symbol = short_symbol;
        _decimals = token_decimals;
        maxSupply = token_maxSupply;
        _tokenPrice = token_price;
    }

    /**
     * @notice decimals will return the number of decimal precision the Token is deployed with
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @notice symbol will return the Token's symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice name will return the Token's symbol
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @notice totalSupply will return the tokens total supply of tokens
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice balanceOf will return the account balance for the given account
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice sellPrice will return the sell price of token
     */
    function sellPrice() external view returns (uint256) {
        return _tokenPrice;
    }

    function setSellPrice(uint256 tokenPrice) external onlyCommunity {
        _tokenPrice = tokenPrice;
    }

    function setSalePaused(bool saleStatus) external onlyCommunity {
        salePaused = saleStatus;
    }

    /**
     * @notice Start the public sale
     */
    function publicSaleStart(uint256 token_price) external onlyCommunity {
        require(_publicSaleDate == 0, "BMX: PublicSale aleady started");
        _publicSaleDate = block.timestamp;
        _tokenPrice = token_price;
        emit PublicSaleStarted(block.timestamp, token_price);
    }

    /**
     * @notice calcMonth is the number of months the public sale was performed.
     * If the return value is more than 20, it will return 20.
     */
    function _calcMonth() internal view returns (uint256) {
        uint256 monthCount = 1 + (block.timestamp - _publicSaleDate) / 30 days;
        if (monthCount > 20) monthCount = 20;
        return monthCount;
    }

    /**
     * @notice transferableToken() is a function to calculate the transferable amount of token for one user.
     * @param account : user address
     */
    function transferableToken(address account) public view returns (uint256) {
        uint256 _nubmerOfMonths = _calcMonth();
        uint256 _transferableBalance = _balances[account] -
            ((100 - restrictPercentage * _nubmerOfMonths) *
                _presaledBalances[account]) /
            100;
        return _transferableBalance;
    }

    /**
     * @notice _mint will create tokens on the address inputted and then increase the total supply
     *
     * It will also emit an Transfer event, with sender set to zero address (adress(0))
     *
     * Requires that the address that is recieveing the tokens is not zero address
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BMX: cannot mint to zero address");

        // Increase total supply
        _totalSupply = _totalSupply + amount;
        // Add amount to the account balance using the balance mapping
        _balances[account] = _balances[account] + amount;
        // Emit our event to log the action
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice _burn will destroy tokens from an address inputted and then decrease total supply
     * An Transfer event will emit with receiever set to zero address
     *
     * Requires
     * - Account cannot be zero
     * - Account balance has to be bigger or equal to amount
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BMX: cannot burn from zero address");
        require(
            _balances[account] >= amount,
            "BMX: Cannot burn more than the account owns"
        );

        // Remove the amount from the account balance
        _balances[account] = _balances[account] - amount;
        // Decrease totalSupply
        _totalSupply = _totalSupply - amount;
        // Emit event, use zero address as reciever
        emit Transfer(account, address(0), amount);
    }

    /**
     * @notice _transfer is used for internal transfers
     *
     * Events
     * - Transfer
     *
     * Requires
     *  - modifier restrictTransfer() is used
     *  - Sender cannot be zero
     *  - recipient cannot be zero
     *  - sender balance most be = or bigger than amount + wasting Fee
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal restrictTransfer(sender, amount) {
        require(sender != address(0), "BMX: transfer from zero address");
        require(recipient != address(0), "BMX: transfer to zero address");

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        if (_publicSaleDate == 0) {
            _presaledBalances[sender] -= amount;
            _presaledBalances[recipient] += amount;
        }

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @notice burn is used to destroy tokens on an address
     *
     * See {_burn}
     * Requires
     *   - msg.sender must be the token owner
     *
     */
    function burn(address account, uint256 amount) external returns (bool) {
        _burn(account, amount);
        // Emit event, use zero address as reciever
        emit Transfer(account, address(0), amount);
        return true;
    }

    /**
     * @notice transfer is used to transfer tokens from the sender to the recipient
     * This function is only callable from outside the contract. For internal usage see
     * _transfer
     *
     * Requires
     * - Caller cannot be zero
     * - Caller must have a balance = or bigger than amount
     *
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @notice buyToken is used to transfer tokens from the admin to the buyer
     * This function is only callable from outside the contract. For internal usage see
     * _transfer
     *
     * Requires
     * - Caller cannot be zero
     * - Caller must have a balance = or bigger than (amount * _tokenPrice)/10**_decimals
     *
     */
    function buyToken(uint256 amount) external payable {
        require(salePaused == false, "BMX: Sale paused");
        require(_totalSupply + amount <= maxSupply, "BMX: Cant buy token");
        require(
            msg.value >= (amount * _tokenPrice) / 10**_decimals,
            "BMX: Insufficient fund"
        );
        _mint(msg.sender, amount);
        if (_publicSaleDate == 0) {
            _presaledBalances[msg.sender] += amount;
        }
        emit BoughtToken(msg.sender, amount);
    }

    /**
     * @notice allowance is used view how much allowance an spender has
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @notice approve will use the senders address and allow the spender to use X amount of tokens on his behalf
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice _approve is used to add a new Spender to a Owners account
     *
     * Events
     *   - {Approval}
     *
     * Requires
     *   - owner and spender cannot be zero address
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(
            owner != address(0),
            "BMX: approve cannot be done from zero address"
        );
        require(
            spender != address(0),
            "BMX: approve cannot be to zero address"
        );
        // Set the allowance of the spender address at the Owner mapping over accounts to the amount
        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice transferFrom is uesd to transfer Tokens from a Accounts allowance
     * Spender address should be the token holder
     *
     * Requires
     *   - The caller must have a allowance = or bigger than the amount spending
     */
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        // Make sure spender is allowed the amount
        require(
            _allowances[spender][msg.sender] >= amount,
            "BMX: You cannot spend that much on this account"
        );
        // Transfer first
        _transfer(spender, recipient, amount);
        // Reduce current allowance so a user cannot respend
        _approve(
            spender,
            msg.sender,
            _allowances[spender][msg.sender] - amount
        );
        return true;
    }

    /**
     * @notice increaseAllowance
     * Adds allowance to a account from the function caller address
     */
    function increaseAllowance(address spender, uint256 amount)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] + amount
        );
        return true;
    }

    /**
     * @notice decreaseAllowance
     * Decrease the allowance on the account inputted from the caller address
     */
    function decreaseAllowance(address spender, uint256 amount)
        external
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender] - amount
        );
        return true;
    }

    /**
     * Add functionality like burn to the _stake afunction
     * @param method is staking method
     * 1 : 6 months staking
     * 2 : 12 months staking
     * 3 : 18 months staking
     * 4 : 24 months staking
     */
    function stake(uint256 _amount, uint8 method) external returns (bool) {
        require(method < 5 && method > 0, "BMX: Wrong input");
        // Make sure staker actually is good for it
        require(
            _amount <= _balances[msg.sender],
            "BMX: Cannot stake more than you own"
        );

        _stake(_amount, msg.sender, method);
        // Burn the amount of tokens on the sender
        _burn(msg.sender, _amount);
        if (_publicSaleDate == 0) {
            _presaledBalances[msg.sender] -= _amount;
        }
        return true;
    }

    /**
     * @notice withdrawStake is used to withdraw stakes from the account holder
     * event {WithdrawStake}
     */
    function withdrawStake(uint256 amount) external {
        StakingSummary memory summary = hasStake(msg.sender);
        // make users cant withdraw unless the staking ended
        uint256 totalWithdrawalbleAmount = summary.total_withdrawable_reward;
        require(
            amount <= totalWithdrawalbleAmount,
            "BMX: Cant withdraw more than available amount"
        );
        // Itterate all stakes and grab amount of stakes
        uint256 usedAmount;
        for (uint256 i = 0; usedAmount < amount; i++) {
            uint256 currentAmount = summary.stakes[i].amount +
                summary.stakes[i].claimable;
            if (usedAmount + currentAmount > amount)
                currentAmount = amount - usedAmount;
            _withdrawStake(currentAmount, i, msg.sender);
            usedAmount += currentAmount;
        }
        // Return staked tokens to user
        _mint(msg.sender, amount);
        // Burn the wasting fee

        emit WithdrawStake(msg.sender, amount);
    }

    /* Withdraw the funds to the community wallet */
    function withdraw(uint256 amount) public onlyCommunity {
        require(
            address(this).balance >= amount,
            "Cant withdraw more than have"
        );
        (bool success, ) = (msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @notice Contract is a inheritable smart contract that will add a
 * New modifier called onlyOwner available in the smart contract inherting it
 *
 * onlyOwner makes a function only callable from the Token owner
 *
 */
contract Ownable {
    // _owner is the owner of the Token
    address private _owner;

    /**
     * Event OwnershipTransferred is used to log that a ownership change of the token has occured
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * Modifier
     * We create our own function modifier called onlyCommunity, it will Require the current owner to be
     * the same as multi-signature wallet address
     */
    modifier onlyCommunity() {
        require(
            _owner == msg.sender,
            "BMX: only community can call this function"
        );
        // This _; is not a TYPO, It is important for the compiler;
        _;
    }

    constructor() {
        _owner = 0x4AE8461540b17Ab94D7a055f4073eA2EF93c6D01; // Community wallet address
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @notice owner() returns the currently assigned owner of the Token
     *
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice renounceOwnership will set the owner to zero address
     * This will make the contract owner less, It will make ALL functions with
     * onlyOwner no longer callable.
     * There is no way of restoring the owner
     */
    function renounceOwnership() external onlyCommunity {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @notice transferOwnership will assign the {newOwner} as owner
     *
     */
    function transferOwnership(address newOwner) external onlyCommunity {
        _transferOwnership(newOwner);
    }

    /**
     * @notice _transferOwnership will assign the {newOwner} as owner
     *
     */
    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @notice Stakeable is a contract who is ment to be inherited by other contract that wants Staking capabilities
 */
contract Stakeable {
    /**
     * @notice Constructor since this contract is not ment to be used without inheritance
     * push once to stakeholders for it to work proplerly
     */
    constructor() {
        // This push is needed so we avoid index 0 causing bug of index-1
        stakeholders.push();
    }

    /**
     * @notice
     * A stake struct is used to represent the way we store stakes,
     * A Stake will contain the users address, the amount staked and a timestamp,
     * Since which is when the stake was made
     * @param method is staking method
     * 1 : 6 months staking
     * 2 : 12 months staking
     * 3 : 18 months staking
     * 4 : 24 months staking
     */
    struct Stake {
        address user;
        uint256 amount;
        uint256 since;
        // This claimable field is new and used to tell how big of a reward is currently available
        uint256 claimable;
        uint8 method;
    }
    /**
     * @notice Stakeholder is a staker that has active stakes
     */
    struct Stakeholder {
        address user;
        Stake[] address_stakes;
    }
    /**
     * @notice
     * StakingSummary is a struct that is used to contain all stakes performed by a certain account
     */
    struct StakingSummary {
        uint256 total_amount;
        uint256 total_reward;
        uint256 total_withdrawable_reward;
        Stake[] stakes;
    }

    /**
     * @notice
     *   This is a array where we store all Stakes that are performed on the Contract
     *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
     */
    Stakeholder[] internal stakeholders;
    /**
     * @notice
     * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) internal stakes;
    /**
     * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 index,
        uint256 timestamp,
        uint8 method
    );

    /**
     * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256) {
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex;
    }

    /**
     * @notice
     * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
     * StakeID
     */
    function _stake(
        uint256 _amount,
        address account,
        uint8 method
    ) internal {
        // Simple check so that user does not stake 0
        require(_amount > 0, "Cannot stake nothing");

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[account];
        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 timestamp = block.timestamp;
        // See if the staker already has a staked index or if its the first time
        if (index == 0) {
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(account);
        }

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakeholders[index].address_stakes.push(
            Stake(account, _amount, timestamp, 0, method)
        );
        // Emit an event that the stake has occured
        emit Staked(account, _amount, index, timestamp, method);
    }

    /**
     * @notice
     * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
     * and the duration the stake has been active
     * Staking reward calculation
     */
    function calculateStakeReward(Stake memory _current_stake)
        internal
        view
        returns (uint256)
    {
        uint256 _reward;

        // 6 Month - 12%
        // 12 Month - 30%
        // 18 Month - 45%
        // 24 Months - 70%

        uint256 _months = (block.timestamp - _current_stake.since) / 30 days;

        // Calculation of the rewards according to staking method
        // 1 : 6 months staking method
        // 2 : 12 months staking method
        // 3 : 18 months staking method
        // 4 : 24 months staking method
        if (_current_stake.method == 1) {
            if (_months > 6) _months = 6;
            _reward = (_current_stake.amount * 12 * _months) / 100 / 6;
        } else if (_current_stake.method == 2) {
            if (_months > 12) _months = 12;
            _reward = (_current_stake.amount * 30 * _months) / 100 / 12;
        } else if (_current_stake.method == 3) {
            if (_months > 18) _months = 18;
            _reward = (_current_stake.amount * 45 * _months) / 100 / 18;
        } else {
            if (_months > 24) _months = 24;
            _reward = (_current_stake.amount * 70 * _months) / 100 / 24;
        }
        return _reward;
    }

    /**
     * @notice
     * withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
     * Notice index of the stake is the users stake counter, starting at 0 for the first stake
     * Will return the amount to MINT onto the acount
     * Will also calculateStakeReward and reset timer
     */
    function _withdrawStake(
        uint256 amount,
        uint256 index,
        address account
    ) internal {
        // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[account];
        Stake memory current_stake = stakeholders[user_index].address_stakes[
            index
        ];
        uint256 reward = calculateStakeReward(current_stake);
        require(
            current_stake.amount + reward >= amount,
            "Staking: Cannot withdraw more than you have staked"
        );

        // Remove by subtracting the money unstaked

        if (current_stake.amount + reward == amount) {
            current_stake.amount = 0;
            delete stakeholders[user_index].address_stakes[index];
        } else {
            // If not empty then replace the value of it
            uint256 replaceAmount;
            // 1 : 6 months staking method
            // 2 : 12 months staking method
            // 3 : 18 months staking method
            // 4 : 24 months staking method
            if (current_stake.method == 1) {
                replaceAmount = (amount * 100) / (100 + 12);
            } else if (current_stake.method == 2) {
                replaceAmount = (amount * 100) / (100 + 30);
            } else if (current_stake.method == 3) {
                replaceAmount = (amount * 100) / (100 + 45);
            } else {
                replaceAmount = (amount * 100) / (100 + 70);
            }
            current_stake.amount -= replaceAmount;
            stakeholders[user_index]
                .address_stakes[index]
                .amount = current_stake.amount;
        }
    }

    /**
     * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
     */
    function hasStake(address _staker)
        public
        view
        returns (StakingSummary memory)
    {
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount;
        uint256 totalRewardAmount;
        uint256 totalWithdrawableRewardAmount;
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(
            totalStakeAmount,
            totalRewardAmount,
            totalWithdrawableRewardAmount,
            stakeholders[stakes[_staker]].address_stakes
        );
        // Itterate all stakes and grab amount of stakes
        uint256 stakeLength = summary.stakes.length;
        for (uint256 s = 0; s < stakeLength; s += 1) {
            uint256 availableReward = calculateStakeReward(summary.stakes[s]);
            summary.stakes[s].claimable = availableReward;
            totalRewardAmount += availableReward;
            totalStakeAmount += summary.stakes[s].amount;
            // Withdrawable reward calculation
            uint256 _months = (block.timestamp - summary.stakes[s].since) /
                30 days;
            if (_months >= 6 * summary.stakes[s].method)
                totalWithdrawableRewardAmount +=
                    summary.stakes[s].amount +
                    availableReward;
        }
        // Assign calculate amount to summary
        summary.total_amount = totalStakeAmount;
        summary.total_reward = totalRewardAmount;
        summary.total_withdrawable_reward = totalWithdrawableRewardAmount;
        return summary;
    }
}