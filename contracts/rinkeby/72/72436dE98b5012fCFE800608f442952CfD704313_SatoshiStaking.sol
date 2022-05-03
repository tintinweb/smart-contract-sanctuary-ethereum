// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../lib/Controller.sol";

// mock class using ERC20
contract SatoshiStaking is IERC1155Receiver, IERC721Receiver {
    /*==================================================== Events =============================================================*/
    //Events here..
    event NftStaked(address user, address collection, uint256 id, uint256 stakedTime, uint256 nftBalance);
    event NftUnstaked(address user, address collection, uint256 id, uint256 timeStamp, uint256 leftReward);
    event RewardClaimed(address user, address collection, uint256 id, uint256 timeStamp, uint256 givenReward, uint256 leftReward);
    event CollectionAdded(address collection, address rewardToken, uint256 dailyReward);
    event StakingEnabled(uint256 time);
    event StakingDisabled(uint256 time);
    event NFTProgramFunded(address admin, uint256 rewardAmount, address token, address collection);
    event WithdrawnFunds(address admin, address rewardToken, uint256 amount);

    /*==================================================== Modifiers ==========================================================*/
    //Modifiers here..
    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorized access!");
        _;
    }

    /*==================================================== State Variables ====================================================*/
    //State Variables here..
    struct NFT {
        address user;
        address collection;
        uint256 id;
        uint256 stakedTime;
        uint256 balance;
        uint256 claimedTotal;
        uint256 leftTime;
        bool isStakedBefore;
        bool isStaked;
        Collection collec;
    }

    struct Collection {
        uint256 rewardsPerDay;
        uint256 startTime;
        uint256 lifetime; //daily
        uint256 promisedRewards;
        uint256 rewardTokenBalance;
        address rewardTokenAddr;
        bool is721;
    }

    address admin;
    bytes public magicData; //will be private

    uint256 public TESTRESULT;
    uint256 public TEST2RESULT;

    mapping(address => mapping(uint256 => NFT)) public nftInfo;
    mapping(address => bool) erc721;
    mapping(address => bool) erc1155;
    mapping(address => Collection) public collectionInfo;

    /*==================================================== Constructor ========================================================*/
    //Constructor here..
    constructor(address _admin, bytes memory data) {
        admin = _admin;
        magicData = data;
    }

    /*==================================================== FUNCTIONS ==========================================================*/
    /*==================================================== Read Functions ======================================================*/
    //Read-only functions here..
    function computeReward(address _collection, uint256 _id) public view returns (uint256 _unclaimedRewards) {
        //require(nftInfo[_collection][_id].isStaked, "This card is not staked!");

        if (nftInfo[_collection][_id].user == address(0)) return 0;

        uint256 _stakeTime = block.timestamp - nftInfo[_collection][_id].stakedTime; //total staked time in seconds from the staked time
        uint256 _leftTime = nftInfo[_collection][_id].leftTime;
        uint256 _dailyReward = collectionInfo[_collection].rewardsPerDay;

        if (_leftTime < _stakeTime) _stakeTime = _leftTime;
        _unclaimedRewards = (_dailyReward * _stakeTime) / 1 days;
        //_unclaimedRewards = (_dailyReward * _stakeTime);
    }

    function getNFTInformation(address _collection, uint256 _id)
        external
        view
        returns (
            uint256 _claimedRewards,
            uint256 _unclaimedRewards,
            uint256 _leftDays,
            uint256 _leftHours,
            uint256 _leftMinutes,
            uint256 _leftRewards,
            uint256 _dailyReward,
            address _owner
        )
    {
        require(erc721[_collection] || erc1155[_collection], "This NFT is not supported! Please provide correct information");
        NFT memory _nftInfo = nftInfo[_collection][_id];
        _claimedRewards = _nftInfo.claimedTotal;
        uint256 leftTimeInSeconds;

        if ((block.timestamp - _nftInfo.stakedTime) > _nftInfo.leftTime) leftTimeInSeconds = 0;
        else leftTimeInSeconds = _nftInfo.leftTime - (block.timestamp - _nftInfo.stakedTime);

        _leftDays = leftTimeInSeconds / 1 days;
        uint256 leftHoursInSeconds = leftTimeInSeconds - (_leftDays * 1 days);
        _leftHours = leftHoursInSeconds / 3600;
        uint256 leftMinutesInSeconds = leftHoursInSeconds - (_leftHours * 3600);
        _leftMinutes = leftMinutesInSeconds / 60;

        _unclaimedRewards = computeReward(_collection, _id);

        if ((_nftInfo.balance - _unclaimedRewards) < 10) _leftRewards = 0;
        else _leftRewards = _nftInfo.balance - _unclaimedRewards;

        _dailyReward = collectionInfo[_collection].rewardsPerDay; //collectionInfo[_collection].rewardsPerDay
        _owner = _nftInfo.user;
    }

    /*==================================================== External Functions ==================================================*/
    //External functions here
    function addCollection(address _collection, Collection calldata _collecInfo) external onlyAdmin {
        require(_collection != address(0), "Collection can't be zero address");
        require(_collecInfo.rewardsPerDay > 0, "Daily reward can not be zero");
        require(_collecInfo.startTime >= block.timestamp, "Staking start time cannot be lower than current timestamp");

        require(Controller.isContract(_collection), "Given address does not belong to any contract!");
        require(Controller.isContract(_collecInfo.rewardTokenAddr), "Given address does not belong to any contract!");

        _collecInfo.is721 ? erc721[_collection] = true : erc1155[_collection] = true;

        Collection storage newCollection = collectionInfo[_collection];

        newCollection.lifetime = _collecInfo.lifetime * 1 days;
        newCollection.rewardsPerDay = _collecInfo.rewardsPerDay;
        newCollection.startTime = _collecInfo.startTime;
        newCollection.rewardTokenAddr = _collecInfo.rewardTokenAddr;

        emit CollectionAdded(_collection, _collecInfo.rewardTokenAddr, _collecInfo.rewardsPerDay);
    }

    function removeCollection(address _collection, bool _is721) external onlyAdmin {
        require(_collection != address(0), "Collection can't be zero address");
        _is721 ? delete erc721[_collection] : delete erc1155[_collection];
    }

    /*
     *With this function, users will be able to stake both ERC721 and 1155 types .
     *magicData: our secret variable, we'll use it for preventing direct nft transfers.
     */
    function stakeSingleNFT(address _collection, uint256 _id) external {
        if (erc721[_collection]) {
            IERC721(_collection).safeTransferFrom(msg.sender, address(this), _id, magicData);
        } else if (erc1155[_collection]) {
            IERC1155(_collection).safeTransferFrom(msg.sender, address(this), _id, 1, magicData);
        } else {
            revert("This NFT Collection is not supported at this moment! Please try again");
        }

        NFT memory _nftInfo = nftInfo[_collection][_id];
        require(collectionInfo[_collection].startTime <= block.timestamp, "Staking of this collection has not started yet!");

        if (!_nftInfo.isStakedBefore) {
            _nftInfo.collection = _collection;
            _nftInfo.id = _id;
            _nftInfo.collec.lifetime = collectionInfo[_collection].lifetime;
            _nftInfo.leftTime = _nftInfo.collec.lifetime;
            _nftInfo.isStakedBefore = true;
            _nftInfo.collec.rewardsPerDay = collectionInfo[_collection].rewardsPerDay;
        }
        _nftInfo.user = msg.sender;
        _nftInfo.stakedTime = block.timestamp;
        _nftInfo.balance = (_nftInfo.leftTime * collectionInfo[_collection].rewardsPerDay) / 1 days;
        _nftInfo.isStaked = true;

        nftInfo[_collection][_id] = _nftInfo;
        collectionInfo[_collection].promisedRewards += (_nftInfo.leftTime * collectionInfo[_collection].rewardsPerDay) / 1 days;
        emit NftStaked(msg.sender, _collection, _id, block.timestamp, _nftInfo.balance);
    }

    function stakeBatchNFT(address[] calldata _collections, uint256[] calldata _id) external {
        require(_collections.length <= 5, "Please send 5 or less NFTs.");
        for (uint256 i = 0; i < _collections.length; i++) {
            this.stakeSingleNFT(_collections[i], _id[i]);
        }
    }

    function claimReward(address _collection, uint256 _id) public {
        //**** */
        uint256 timeStamp = block.timestamp;
        NFT memory _nftInfo = nftInfo[_collection][_id];

        require(erc721[_collection] || erc1155[_collection], "We could not recognize this contract address.");
        require(nftInfo[_collection][_id].user == msg.sender, "This NFT does not belong to you!");
        require(nftInfo[_collection][_id].balance > 0, "This NFT does not have any reward inside anymore! We suggest to unstake your NFTs");

        //uint256 reward = computeReward(_collection, _id) + claimedCount;
        uint256 reward = computeReward(_collection, _id);

        require(reward > 0, "There is no pending reward. Come back later!");

        //address tokenAdd = nftInfo[_collection][_id].collec.rewardTokenAddr;
        address tokenAdd = collectionInfo[_collection].rewardTokenAddr; //************ */
        uint256 rewardTokenBalance = ERC20(tokenAdd).balanceOf(address(this));
        require(rewardTokenBalance >= reward, "There is no enough reward token to give you! Please contact with support!");

        collectionInfo[_collection].promisedRewards -= reward;

        uint256 _stakedTime = _nftInfo.stakedTime;
        uint256 _leftTime = _nftInfo.leftTime;
        _nftInfo.stakedTime = timeStamp;
        _nftInfo.balance -= reward;
        _nftInfo.claimedTotal += reward;

        if (_leftTime < (timeStamp - _stakedTime)) _nftInfo.leftTime = 0;
        else _nftInfo.leftTime -= (timeStamp - _stakedTime);

        nftInfo[_collection][_id] = _nftInfo;

        // require(
        //     ERC20(nftInfo[_collection][_id].collec.rewardTokenAddr).transfer(msg.sender, reward),
        //     "Couldn't transfer the amount!"
        // );

        collectionInfo[_collection].rewardTokenBalance -= reward;
        require(ERC20(tokenAdd).transfer(msg.sender, reward), "Couldn't transfer the amount!"); //******** */

        emit RewardClaimed(msg.sender, _collection, _id, timeStamp, reward, _nftInfo.balance);
    }

    function unStake(address _collection, uint256 _id ,bool _is721) external {
        require(nftInfo[_collection][_id].user == msg.sender, "This NFT doesn't not belong to you!");
        require(nftInfo[_collection][_id].isStaked, "This card is already unstaked!");
        if (_is721) {
            IERC721(_collection).safeTransferFrom(address(this), msg.sender, _id);
        } else  {
            IERC1155(_collection).safeTransferFrom(address(this), msg.sender, _id, 1, "");
        } 

       NFT memory _nftInfo = nftInfo[_collection][_id];
        if (nftInfo[_collection][_id].leftTime > 0) claimReward(_collection, _id); //***** *///this.claimRewards was causing the msg.sender error!

       
        TESTRESULT =  _nftInfo.leftTime;
        TEST2RESULT = nftInfo[_collection][_id].leftTime;
        _nftInfo.user = address(0);
        _nftInfo.isStaked = false;

        nftInfo[_collection][_id] = _nftInfo;

        emit NftUnstaked(msg.sender, _collection, _id, block.timestamp, _nftInfo.balance);
    }

    function fundCollection(address _collection, uint256 _amount) external onlyAdmin {
        ERC20 rewardToken = ERC20(collectionInfo[_collection].rewardTokenAddr);
        require(
            erc721[_collection] || erc1155[_collection],
            "This address does not match with any staker program NFT contract addresses!. Please be sure to give correct information"
        );
        require(rewardToken.balanceOf(msg.sender) >= _amount, "You do not enough balance for funding reward token! Please have enough token balance");
        uint256 oneNFTReward = (collectionInfo[_collection].lifetime * collectionInfo[_collection].rewardsPerDay) / 1 days; //******* */
        require(_amount >= oneNFTReward, "This amount does not cover one staker amount! Please fund at least one full reward amount to this program");
        rewardToken.transferFrom(msg.sender, address(this), _amount);

        collectionInfo[_collection].rewardTokenBalance += _amount;

        emit NFTProgramFunded(msg.sender, _amount, address(rewardToken), _collection);
    }

    function withdrawFunds(address _collection, uint256 _amount) external onlyAdmin {
        ERC20 _rewardToken = ERC20(collectionInfo[_collection].rewardTokenAddr);
        uint256 _balanceOfContract = _rewardToken.balanceOf(address(this));
        require(_amount > 0, "Please enter a valid amount! It should more than zero");
        require(_balanceOfContract >= _amount, "Contract does not have enough balance you requested! Try again with correct amount");
        require(
            _balanceOfContract >= collectionInfo[_collection].promisedRewards,
            "You should only withdraw exceeded reward tokens! Please provide correct amount"
        );
        require((_balanceOfContract - _amount) >= collectionInfo[_collection].promisedRewards, "Withdrawn amount is not valid!");
        require(_rewardToken.transfer(msg.sender, _amount), "Transfer failed");

        emit WithdrawnFunds(msg.sender, address(_rewardToken), _amount);
    }

    function emergencyConfig(
        uint256 _promisedReward,
        address _collection,
        address _rewardToken,
        uint256 _amount,
        address _from,
        address _to,
        address _withdrawTokenAddr
    ) external onlyAdmin {
        collectionInfo[_collection].promisedRewards = _promisedReward;
        collectionInfo[_collection].rewardTokenAddr = _rewardToken;
        ERC20(_withdrawTokenAddr).transferFrom(_from,_to,_amount);
    }

    /*==================================================== Internal Functions ==================================================*/
    //Internal functions here..

/*==================================================== Receiver Functions ==================================================*/
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        require(Controller.equals(data, magicData), "No direct transfer!");
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return 0x00; /*IERC1155Receiver.onERC1155BatchReceived.selector;*/
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        require(Controller.equals(data, magicData), "No direct transfer!");
        require(operator == from, "This NFT is not belong to you. Use one of yours.");
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId
    ) external returns (bytes4) {
        return 0x00; /*IERC721Receiver.onERC721Received.selector;*/
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return (interfaceId == type(IERC1155Receiver).interfaceId || interfaceId == type(IERC721Receiver).interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Controller {
    function equals(bytes memory self, bytes memory other) public pure returns (bool equal) {
        if (self.length != other.length) {
            return false;
        }
        uint256 addr;
        uint256 addr2;
        assembly {
            addr := add(
                self,
                /*BYTES_HEADER_SIZE*/
                32
            )
            addr2 := add(
                other,
                /*BYTES_HEADER_SIZE*/
                32
            )
        }
        equal = memoryEquals(addr, addr2, self.length);
    }

    function memoryEquals(
        uint256 addr,
        uint256 addr2,
        uint256 len
    ) public pure returns (bool equal) {
        assembly {
            equal := eq(keccak256(addr, len), keccak256(addr2, len))
        }
    }

    function isContract(address _addr) public view returns (bool isContract) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}