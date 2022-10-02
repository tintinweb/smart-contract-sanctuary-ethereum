// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Kills is ReentrancyGuard, ERC20 {
    
    struct Hunters {
        uint256 amountHunting;
        uint256 timeOfHunting;
        uint256 deposit;
    }

    struct JoinRaffle {
        address addressRaffle;
        uint256 amountRaffle;
    }

    struct JoinLuckyChance {
        address addressLuckyChance;
        string prizeLuckyChance;
    }  
    
    IERC721 public IMechaApe;
    IERC721 public IMechaHound;
    address public owner;
    mapping(string => JoinLuckyChance[]) public LuckyChance;
    mapping(string => JoinRaffle[]) public Raffle;
    mapping(string => uint256) public RafflePrice;
    mapping(string => address) public RaffleWinner;
    uint256 public MechaApeRatio;
    uint256 public MechaHoundRatio;
    uint256 private rewardsPerHour = 33333;
    string public Empty = "";
    mapping(address => Hunters) public MechaStake;
    mapping(uint256 => address) public MechaApeStakeAddress;
    mapping(uint256 => address) public MechaHoundStakeAddress;
    mapping(address => uint256[]) public MechaApeStakeToken;
    mapping(address => uint256[]) public MechaHoundStakeToken;
    address[] public MechaStakeArray;
    uint256 public LuckyChancePrice;
    bool public isRaffle; 
    bool public isLuckyChance; 
    bool public isFeature; 

    constructor(IERC721 _mechaApe,IERC721 _mechaHound,string memory _name, string memory _symbol)ERC20(_name, _symbol){
        IMechaApe = _mechaApe;
        IMechaHound = _mechaHound;
        owner = msg.sender;
    }

    function _onlyOwner() private view{
        require(msg.sender == owner, "not Owner");
    }

    function newOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    modifier onlyOwner(){
        _onlyOwner();
        _;
    }

    function onTransferKills(address to ,uint256 amount) public nonReentrant {
        require(isFeature, "not Active");
        require(balanceOf(_msgSender()) >= amount, "Insufficient balance");
        MechaStake[msg.sender].deposit -= amount;
        MechaStake[to].deposit += amount;
    }

    function onDepositKills(uint256 amount) public nonReentrant {
        require(isFeature, "not Active");
        require(balanceOf(_msgSender()) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);
        MechaStake[msg.sender].deposit += amount;
    }

    function onWithdrawKills() external nonReentrant {
        require(isFeature, "not Active");
        uint256 rewardKills = calculateKills(msg.sender) + MechaStake[msg.sender].deposit;
        require(rewardKills > 0, "You dont' have any $Kills to claim");
        MechaStake[msg.sender].timeOfHunting = block.timestamp;
        MechaStake[msg.sender].deposit = 0;
        _mint(msg.sender, rewardKills);
    }

    function onMoveKills() external nonReentrant {
        require(isFeature, "not Active");
        uint256 rewardKills = calculateKills(msg.sender) + MechaStake[msg.sender].deposit;
        require(rewardKills > 0, "You dont' have any $Kills to claim");
        MechaStake[msg.sender].timeOfHunting = block.timestamp;
        MechaStake[msg.sender].deposit = rewardKills;
    }

    function onRaffleJoin(uint256 amount,string memory raffleName) external nonReentrant {
        require(isRaffle, "not Active");
        uint256 rafflePrice = RafflePrice[raffleName];
        require(amount >= rafflePrice, "Not Enough $Kills");
        JoinRaffle memory newStruct = JoinRaffle(msg.sender,amount);
        Raffle[raffleName].push(newStruct);
        MechaStake[msg.sender].deposit -= amount;
    }
    
    function onLuckyChance(uint256 amount,string memory luckyChanceName) external nonReentrant returns(string memory) {
        require(isLuckyChance, "not Active");
        require(amount >= LuckyChancePrice, "Not Enough $Kills");
        require(MechaStake[msg.sender].deposit >= amount, "Not Enough $Kills");
        uint256 burn = amount;
        uint256 random = generateRandomNumberLuckyChance(luckyChanceName);
        if(keccak256(abi.encodePacked(LuckyChance[luckyChanceName][random].prizeLuckyChance)) != keccak256(abi.encodePacked(Empty)))
        {
            if(LuckyChance[luckyChanceName][random].addressLuckyChance == address(0))
            {
                LuckyChance[luckyChanceName][random].addressLuckyChance = msg.sender;
                return LuckyChance[luckyChanceName][random].prizeLuckyChance;
            }
            else{
                burn = generateRandomNumberCoin();
                return Strings.toString(burn);
            }
        }
        else{
            burn = generateRandomNumberCoin();
        }
        MechaStake[msg.sender].deposit -= burn;
        return Strings.toString(burn);
    }
    
    function RaffleDeclareWinner(string memory raffleName) public onlyOwner {
        require(Raffle[raffleName].length > 0);
        uint index = generateRandomNumberRaffle(raffleName) % Raffle[raffleName].length;
        address winner = Raffle[raffleName][index].addressRaffle;
        RaffleWinner[raffleName] = winner;
    }     

    function setIsFeature(bool _isDeposit,bool _isFeature , bool _isLuckyChance)public onlyOwner {
        isRaffle =_isDeposit; 
        isFeature =_isFeature; 
        isLuckyChance =_isLuckyChance; 
    }
    
    function setPrizeLucky(string memory LuckyChanceName,string[] memory prizeLuckyChance) public onlyOwner {
        for (uint256 i = 0; i < prizeLuckyChance.length; ++i) {
            JoinLuckyChance memory newStruct = JoinLuckyChance(address(0),prizeLuckyChance[i]);
            LuckyChance[LuckyChanceName].push(newStruct);
        }
    }  

    function generateRandomNumberRaffle(string memory raffleName) internal view returns (uint) {
        return uint256(keccak256(abi.encodePacked(block.timestamp))) % (Raffle[raffleName].length);
    }
    
    function generateRandomNumberLuckyChance(string memory raffleName) internal view returns (uint) {
        return uint256(keccak256(abi.encodePacked(block.timestamp))) % (LuckyChance[raffleName].length);
    }
    
    function generateRandomNumberCoin() internal view returns (uint) {
        return uint256(keccak256(abi.encodePacked(block.timestamp))) % (LuckyChancePrice);
    }

    function MechaStakeList() internal view returns (uint256 __length) {
        return (MechaStakeArray.length);
    }

    function Stake(uint256[] calldata _idMechaApe , uint256[] calldata _idMechaHound) external nonReentrant {

        uint mechaApe = uint(_idMechaApe.length*10)/MechaApeRatio;
        uint mechaHound = uint(_idMechaHound.length*10)/MechaHoundRatio;
        uint256 lenMechaHApe = _idMechaApe.length;
        uint256 lenMechaHound = _idMechaHound.length;

        require(mechaApe == mechaHound, string(abi.encodePacked("Need 2:1 Staking | ",MechaApeRatio," Mecha Apes : ", MechaHoundRatio," Mecha Hound")));
        if (MechaStake[msg.sender].amountHunting > 0) {
            uint256 rewardsMechaApe = calculateKills(msg.sender);
            MechaStake[msg.sender].deposit += rewardsMechaApe;
        } else {
            MechaStakeArray.push(msg.sender);
        }
        for (uint256 i; i < lenMechaHApe; ++i) {
            IMechaApe.transferFrom(msg.sender, address(this), _idMechaApe[i]);
            MechaApeStakeAddress[_idMechaApe[i]] = msg.sender;
            MechaApeStakeToken[msg.sender].push(_idMechaApe[i]);
        }
        for (uint256 i; i < lenMechaHound; ++i) {
            IMechaHound.transferFrom(msg.sender, address(this), _idMechaHound[i]);
            MechaHoundStakeAddress[_idMechaHound[i]] = msg.sender;
            MechaHoundStakeToken[msg.sender].push(_idMechaHound[i]);
        }
        MechaStake[msg.sender].amountHunting += lenMechaHApe+lenMechaHound;
        MechaStake[msg.sender].timeOfHunting = block.timestamp;
    }

    function UnStake(uint256[] calldata _idMechaApe , uint256[] calldata _idMechaHound) external nonReentrant {

        uint mechaApe = uint(_idMechaApe.length*10)/MechaApeRatio;
        uint mechaHound = uint(_idMechaHound.length*10)/MechaHoundRatio;
        require(mechaApe == mechaHound, string(abi.encodePacked("Need 2:1 Staking | ",MechaApeRatio," Mecha Apes : ", MechaHoundRatio," Mecha Hound")));
        require(MechaStake[msg.sender].amountHunting > 0, "Don't have any NFT Staked");
        uint256 rewardsMechaApe = calculateKills(msg.sender);
        MechaStake[msg.sender].deposit += rewardsMechaApe;
        uint256 lenMechaApe = _idMechaApe.length;
        for (uint256 i; i < lenMechaApe; ++i) {
            require(MechaApeStakeAddress[_idMechaApe[i]] == msg.sender, "Can't Withdraw tokens you don't own!");
            MechaApeStakeAddress[_idMechaApe[i]] = address(0);
            IMechaApe.transferFrom(address(this), msg.sender, _idMechaApe[i]);
            for (uint256 j; j < MechaApeStakeToken[msg.sender].length; ++j) {
                if(MechaApeStakeToken[msg.sender][j] ==_idMechaApe[i]){
                    MechaApeStakeToken[msg.sender][j] = MechaApeStakeToken[msg.sender][MechaApeStakeToken[msg.sender].length - 1];
                    MechaApeStakeToken[msg.sender].pop();
                }
            }
        }
        uint256 lenMechaHound = _idMechaHound.length;
        for (uint256 i; i < lenMechaHound; ++i) {
            require(MechaHoundStakeAddress[_idMechaHound[i]] == msg.sender, "Can't Withdraw tokens you don't own!");
            MechaHoundStakeAddress[_idMechaHound[i]] = address(0);
            IMechaHound.transferFrom(address(this), msg.sender, _idMechaHound[i]);
            for (uint256 j; j < MechaHoundStakeToken[msg.sender].length; ++j) {
                if(MechaHoundStakeToken[msg.sender][j] ==_idMechaApe[i]){
                    MechaHoundStakeToken[msg.sender][j] = MechaHoundStakeToken[msg.sender][MechaHoundStakeToken[msg.sender].length - 1];
                    MechaHoundStakeToken[msg.sender].pop();
                }
            }
        }
        MechaStake[msg.sender].amountHunting -= lenMechaApe+lenMechaHound;
        MechaStake[msg.sender].timeOfHunting = block.timestamp;
        if (MechaStake[msg.sender].amountHunting == 0) {
            for (uint256 i; i < MechaStakeArray.length; ++i) {
                if (MechaStakeArray[i] == msg.sender) {
                    MechaStakeArray[i] = MechaStakeArray[MechaStakeArray.length - 1];
                    MechaStakeArray.pop();
                }
            }
        }
    }

    function setRewardsPerHour(uint256 _newValue) public onlyOwner {
        address[] memory _stakersMechaApe = MechaStakeArray;
        uint256 length = _stakersMechaApe.length;
        for (uint256 i; i < length; ++i) {
            address user = _stakersMechaApe[i];
            MechaStake[user].deposit += calculateKills(user);
            MechaStake[msg.sender].amountHunting = block.timestamp;
        }
        rewardsPerHour = _newValue;
    }

    function setLuckyChancePrice(uint256 _luckyChancePrice) public onlyOwner {
        LuckyChancePrice = _luckyChancePrice;
    }

    function setRafflePrice(string memory raffleName, uint256 _raffleChancePrice) public onlyOwner {
        RafflePrice[raffleName] = _raffleChancePrice;
    }

    function setEmptyLuckyChance(string memory emptyName) public onlyOwner {
        Empty = emptyName;
    }

    function setRatioStaking(uint256 _mechaApe,uint256 _mechaHound) public onlyOwner {
        MechaApeRatio = _mechaApe;
        MechaHoundRatio = _mechaHound;
    }

    function addressDetail(address _user) public view returns (uint256 _tokensMechaHoundStaked, uint256 _availableRewards)
    {
        return (MechaStake[_user].amountHunting, availableRewardsKills(_user));
    }

    function availableRewardsKills(address _user) internal view returns (uint256) {
        if (MechaStake[_user].amountHunting == 0) 
        {
            return MechaStake[_user].deposit;
        }
        uint256 _rewards = MechaStake[_user].deposit + calculateKills(_user);
        return _rewards;
    }
    
    function calculateKills(address _staker) internal view returns (uint256 _rewards)
    {
        Hunters memory staker = MechaStake[_staker];
        return (((((block.timestamp - staker.timeOfHunting) * staker.amountHunting)) * rewardsPerHour) / 3600);
    }

    function TotalReward(address _staker) public view returns (uint256 _rewards)
    {
        return (availableRewardsKills(_staker));
    }
    function MechaApeLength(address _staker) public view returns (uint256 Length)
    {
        return (MechaApeStakeToken[_staker].length);
    }
    function MechaHoundLength(address _staker) public view returns (uint256 Length)
    {
        return (MechaHoundStakeToken[_staker].length);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}