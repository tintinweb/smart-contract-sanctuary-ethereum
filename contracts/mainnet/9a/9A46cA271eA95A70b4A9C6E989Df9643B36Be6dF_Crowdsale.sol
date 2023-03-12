// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./TokenVesting.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Crowdsale is Context, Ownable, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for ERC20;

    // tokens and contracts
    ERC20 public immutable token;
    IERC721 public immutable memberCard;
    TokenVesting public immutable vestingContract;

    // sale addresses
    address payable public treasury_1;
    address payable public treasury_2;
        
    // rates
    uint256 public constant tokenAmountRateOne = 1667; // per ETH // 40% off -> 66% more tokens
    uint256 public constant tokenAmountRateTwo = 1250;  // per ETH // 20% off -> 25% more tokens
    uint256 public constant tokenAmountRateThree = 1000;  // per ETH 
    uint256 public tokensRaised;

    // limits
    uint256 public limitPhaseOne; 
    uint256 public limitPhaseTwo; 
    uint256 public limitPhaseThree;

    uint256 public constant minimumBuyAmount = 1 * 1e16; // 0.01 ETH
    bool public isIcoCompleted = false;
    bool public hasIcoPaused = false;

    // round handlers (there are three presale rounds): for member card holders, for whitelisted addresses and public
    bool public isIcoFirstRoundCompleted = false;
    bool public isIcoSecondRoundCompleted = false;
    uint256 public startCrowdsaleTime;
    uint256 public startSecondRoundTime;
    uint256 public startThirdRoundTime;
    uint256 public whiteListSpots = 100;
    bool public extendedRoundOne = false;
    bool public extendedRoundTwo = false;

    // whitelisted addressed
    mapping(address => bool) public whiteListed;

    event TokenBuy(address indexed buyer, uint256 value, uint256 amount);
    event Whitelist(address indexed whitelisted);
    event WhitelistMultiple(address[] addresses, bool value);
    event Close();
    event SetTime(string indexed round, uint256 timestamp);
    event TreasuryChanged(address treasury1, address treasury2);
    event Paused(bool paused);
    event ExtendFirstRound(bool extended);
    event ExtendSecondRound(bool extended);

    modifier whenIcoCompleted() {
        require(
            isIcoCompleted,
            "Crowdsale: crowdsale not completed");
        _;
    }

    modifier onlyAfterStart() {
        uint256 _startTime = startCrowdsaleTime;
        require(
            block.timestamp >= _startTime && _startTime != 0,
            "Crowdsale: crowdsale not started yet"
        );
        _;
    }

    modifier onlyWhenNotPaused() {
        require(
            !hasIcoPaused, 
            "Crowdsale: crowdsale has paused");
        _;
    }

    modifier onlyWhenNotCompleted() {
        require(
            !isIcoCompleted, 
            "Crowdsale: crowdsale has completed");
        _;
    }

    /**
     * @param _token erc20 token address
     * @param _treasury_1 first treasury address
     * @param _treasury_2 second treasury address
     * @param _memberCard erc721 member card
     * @param _vestingContract address of vesting contract
     */
    constructor(
        address _token,
        address payable _treasury_1,
        address payable _treasury_2,
        address _memberCard,
        address _vestingContract
    ) {
        require(
            _token != address(0),
            "Crowdsale: invalid zero address for token provided"
        );
        require(
            _vestingContract != address(0),
            "Crowdsale: invalid zero address for vest provided"
        );
        require(
            _memberCard != address(0),
            "Crowdsale: invalid zero address for member card"
        );
        require(
            _treasury_1 != address(0) && _treasury_2 != address(0),
            "Crowdsale: invalid zero address for treasury addresses"
        );
        // startCrowdsaleTime = block.timestamp;
        vestingContract = TokenVesting(_vestingContract);
        token = ERC20(_token);
        memberCard = IERC721(_memberCard);
        treasury_1 = _treasury_1;
        treasury_2 = _treasury_2;

        uint256 _decimals = ERC20(_token).decimals();
        limitPhaseOne = 75 * 1e3 * (10**_decimals); // + 75k
        limitPhaseTwo = 225 * 1e3 * (10**_decimals); // + 150k (225k)
        limitPhaseThree = 525 * 1e3 * (10**_decimals); // + 300k (525k)
    }

    /**
     * @dev Set white list address.
     * onlyOwner protected.
     * @param _grantees array of grantee addresses
     * @param set are the _grantees to be whitelisted (true) or revoked (false)?
     */
    function setWhitelist(address[] calldata _grantees, bool set) public onlyOwner {
        // add addresses to whitelist
        for (uint i = 0; i < _grantees.length; i++) {
            require(_grantees[i] != address(0), "Crowdsale: Invalid address for grantee");
            whiteListed[_grantees[i]] = set;
        }
        emit WhitelistMultiple(_grantees, set);
    }

    /**
     * @dev Allow users to secure one of the limited whitelist spots.
     * Cannot be called after presale has started.
     */
    function secureWhitelistSpot() external {
        uint256 _spots = whiteListSpots;
        require(
            block.timestamp < startCrowdsaleTime,
            "Crowdsale: crowdsale already started"
        );
        require(_spots > 0, 
            "Crowdsale: no spot left.");
        require(!whiteListed[msg.sender], 
            "Crowdsale: already whitelisted.");
        whiteListSpots = _spots - 1;
        whiteListed[msg.sender] = true;
        emit Whitelist(msg.sender);
    }

    /**
     * @dev Set treasury addresses.
     * onlyOwner protected.
     * @param _treasury_1 first treasury address
     * @param _treasury_2 second treasury address
     */
    function setTreasury(address payable _treasury_1, address payable _treasury_2) public onlyOwner {
        require (_treasury_1 != address(0), "Crowdsale: invalid address 1");
        require (_treasury_2 != address(0), "Crowdsale: invalid address 2");
        treasury_1 = _treasury_1;
        treasury_2 = _treasury_2;
        emit TreasuryChanged(treasury_1, treasury_2);
    }
    /**
     * @dev Set white list address.
     * nonReentrant protected.
     * onlyAfterStart protected.
     * onlyWhenNotPaused protected.
     * onlyWhenNotCompleted protected.
     */
    function buyNative() public payable nonReentrant onlyAfterStart onlyWhenNotPaused onlyWhenNotCompleted {
        require(
            tokensRaised < limitPhaseThree,
            "Crowdsale: reached the maximum amount"
        );
        // set user transferred value
        uint256 _amount = msg.value;
        // tokens to buy
        uint256 tokensToBuy = 0;
        uint256 _limitOne = limitPhaseOne;
        uint256 _limitTwo = limitPhaseTwo;
        uint256 _limitThree = limitPhaseThree;
        uint256 _raised = tokensRaised;
        uint256 _2ndRoundTime = startSecondRoundTime;
        uint256 _3rdRoundTime = startThirdRoundTime;

        if (_raised < _limitOne) {
            tokensToBuy = _getTokensAmount(_amount, tokenAmountRateOne);
            // round 1 is only for whitelisted addresses or for wmc card holders if extended
            require(
                whiteListed[_msgSender()] || (extendedRoundOne && memberCard.balanceOf(_msgSender()) > 0) || extendedRoundTwo, 
                "Crowdsale: Sender not whitelisted."
            );
            require(
                (_amount >= minimumBuyAmount) ||
                    // safety case to allow for lower purchase if limit is reached
                    (tokensToBuy >= (_limitOne - _raised)),
                "Crowdsale: minimum eth amount not sent."
            );
            if (_raised + tokensToBuy > _limitOne) {
                // adjust tokensToBuy
                tokensToBuy = _limitOne - _raised;
                // set actual cost based on available tokens
                _amount = _getETHAmount(tokensToBuy, tokenAmountRateOne);
            }
        } else if (_raised < _limitTwo && isIcoFirstRoundCompleted) {
            require(
                _2ndRoundTime > 0 && block.timestamp >= _2ndRoundTime,
                "Crowdsale: second round not started!"
            );
            // only for wmc card holders or public if extended
            require(
                memberCard.balanceOf(_msgSender()) > 0  || extendedRoundTwo, 
                "Crowdsale: only for member card holders."
            );
            tokensToBuy = _getTokensAmount(_amount, tokenAmountRateTwo);
            require(
                (_amount >= minimumBuyAmount) ||
                    (tokensToBuy >= (_limitTwo - _raised)),
                "Crowdsale: minimum eth amount not sent."
            );
            if (_raised + tokensToBuy > _limitTwo) {
                // adjust tokensToBuy
                tokensToBuy = _limitTwo - _raised;
                // set actual cost based on available tokens
                _amount = _getETHAmount(tokensToBuy, tokenAmountRateTwo);
            }
        } else if (_raised < _limitThree && isIcoSecondRoundCompleted) {
            require(
                _3rdRoundTime > 0 && block.timestamp >= _3rdRoundTime,
                "Crowdsale: third round not started!"
            );
            // public presale
            tokensToBuy = _getTokensAmount(_amount, tokenAmountRateThree);
            require(
                (_amount >= minimumBuyAmount) ||
                    (tokensToBuy >= (_limitThree - _raised)),
                "Crowdsale: minimum eth amount not sent."
            );
            if (_raised + tokensToBuy > _limitThree) {
                // adjust tokensToBuy
                tokensToBuy = _limitThree - _raised;
                // set actual cost based on available tokens
                _amount = _getETHAmount(tokensToBuy, tokenAmountRateThree);
            }
        }

        require(
            tokensToBuy > 0,
            "Crowdsale: insufficient output balance."
        );

        token.safeTransfer(address(vestingContract), tokensToBuy);
        // transfer funds to treasury addresses
        uint256 split_1 = _amount / 2;
        treasury_1.transfer(split_1);
        treasury_2.transfer(_amount - split_1);
        if (_amount < msg.value){
            // refund the rest back to sender if _amount < msg.value
            payable(_msgSender()).transfer(msg.value - _amount);
        }
        // non-revokable vest
        vestingContract.vest(_msgSender(), tokensToBuy);
        // check limits for round 1 and 2
        if (_raised + tokensToBuy >= _limitOne) {
            isIcoFirstRoundCompleted = true;
        }
        if (_raised + tokensToBuy >= _limitTwo) {
            isIcoSecondRoundCompleted = true;
        }
        // set raised token amount
        tokensRaised = _raised + tokensToBuy;
        emit TokenBuy(_msgSender(), _amount, tokensToBuy);
    }

    /**
     * @dev Get ETH amount given a _tokenAmount and the respective _tokenAmountRate per ETH.
     * @param _tokenAmount amount of tokens to be purchased
     * @param _tokenAmountRate amount of tokens per eth
     * @return eth cost
     */
    function _getETHAmount(uint256 _tokenAmount, uint256 _tokenAmountRate)
        internal
        pure
        returns (uint256)
    {
        // tokens -> rate * amount -> amount = tokens/rate
        return _tokenAmount / _tokenAmountRate;
    }

    /**
     * @dev Get token amount given a _value and the respective _tokenAmountRate per ETH.
     * @param _value eth value usable for purchase
     * @param _tokenAmountRate amount of tokens per eth
     * @return amount of tokens to be purchased
     */
    function _getTokensAmount(uint256 _value, uint256 _tokenAmountRate)
        internal
        pure
        returns (uint256)
    {
        // tokens -> rate * _value
        return _value * _tokenAmountRate;
    }

    /**
     * @dev Close crowdsale.
     * onlyOwner protected.
     */
    function closeCrowdsale() public onlyOwner {
        isIcoCompleted = true;
        vestingContract.startVesting(block.timestamp);
        emit Close();
    }

    /**
     * @dev Pause crowdsale.
     * onlyOwner protected.
     */
    function togglePauseCrowdsale() public onlyOwner {
        hasIcoPaused = !hasIcoPaused;
        emit Paused(hasIcoPaused);
    }

    /**
     * @dev Start crowdsale.
     * onlyOwner protected.
     * @param _time unix time stamp
     */
    function startCrowdSale(uint256 _time) public onlyOwner{
        require(startCrowdsaleTime == 0, "Crowdsale: already set");
        require(
            _time >= block.timestamp,
            "Crowdsale: can not start in past"
        );
        startCrowdsaleTime = _time;
        emit SetTime("1st", _time);
    }

    /**
     * @dev Start 2nd round.
     * onlyOwner protected.
     * @param _time unix time stamp
     */
    function startSecondRound(uint256 _time) public onlyOwner {
        require(startSecondRoundTime == 0, "Crowdsale: already set");
        require(
            _time >= block.timestamp,
            "Crowdsale: can not start in past"
        );
        startSecondRoundTime = _time;
        emit SetTime("2nd", _time);
    }

   /**
     * @dev Start 3rd round.
     * onlyOwner protected.
     * @param _time unix time stamp
     */
    function startThirdRound(uint256 _time) public onlyOwner {
        require(startThirdRoundTime == 0, "Crowdsale: already set");
        require(
            _time >= block.timestamp,
            "Crowdsale: can not start in past"
        );
        startThirdRoundTime = _time;
        emit SetTime("3rd", _time);
    }

   /**
     * @dev Extend 1st round.
     * onlyOwner protected.
     * @param _extended is the 1st round to be extended for wmc card holder?
     */
    function extendRoundOne(bool _extended) public onlyOwner {
        extendedRoundOne = _extended;
        emit ExtendFirstRound(_extended);
    }

   /**
     * @dev Extend 2nd round.
     * onlyOwner protected.
     * @param _extended is the 2nd round to be extended for public?
     */
    function extendRoundTwo(bool _extended) public onlyOwner {
        extendedRoundTwo = _extended;
        emit ExtendSecondRound(_extended);
    }

    /**
     * @dev Has 2nd round of presale started?
     * @return true if 2nd round has started, else false
     */
    function has2ndRoundStarted() external view returns (bool) {
        return block.timestamp >= startSecondRoundTime && startSecondRoundTime > 0;
    }

    /**
     * @dev Has 3rd round of presale started?
     * @return true if 3rd round has started, else false
     */
    function has3rdRoundStarted() external view returns (bool) {
        return block.timestamp >= startThirdRoundTime && startThirdRoundTime > 0;
    }

   /**
     * @dev Deposit amount of token into the presale contract.
     * onlyOwner protected.
     * @param _amount amount of tokens to be deposited
     */
    function deposit(uint256 _amount) public onlyOwner {
        token.safeTransferFrom(_msgSender(), address(this), _amount);
    }

   /**
     * @dev Transfer remaining tokens if presale is closed earlier.
     * onlyOwner protected.
     */
    function withdraw() public whenIcoCompleted onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.safeTransfer(_msgSender(), balance);
    }
   /**
     * @dev Withdraw any eth left in contract.
     * onlyOwner protected.
     */
    function withdrawETH() public whenIcoCompleted onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TokenVesting is Ownable, ReentrancyGuard {
    using SafeERC20 for ERC20;

    event NewVest(address indexed _from, address indexed _to, uint256 _value);
    event UnlockVest(address indexed _holder, uint256 _value);
    event RevokeVest(address indexed _holder, uint256 _refund);
    event SetCrowdsale(address crowsale);

    struct Vest {
        uint256 value;
        uint256 transferred;
    }

    address public crowdsaleAddress;
    ERC20 public immutable token;
    uint256 public totalVesting;
    uint256 public immutable totalLimit;
    uint256 public constant RELEASES = 3;
    uint256 public constant duration = 30 days; 
    uint256 public constant finishOfVest  = RELEASES * duration;
    mapping(address => Vest) public vests;
    uint256 public start;
    uint256 public finish;

    modifier onlyCrowdsale() {
        require(_msgSender() == crowdsaleAddress, "TokenVesting: Only crowdsale can call this function.");
        _;
    }

    /**
     * @param _token erc20 token address
     */
    constructor(address _token) {
        require(
            _token != address(0),
            "TokenVesting: invalid zero address for token provided"
        );

        token = ERC20(_token);
        // presale limit
        totalLimit = 1e6 * (10**token.decimals());
    }

    /**
     * @dev Set crowdsale address.
     * onlyOwner protected.
     * @param _crowdsaleAddress address of crowdsale contract
     */
    function setCrowdsaleAddress(address _crowdsaleAddress) public onlyOwner {
        require(
            _crowdsaleAddress != address(0),
            "TokenVesting: invalid zero address for crowdsale"
        );
        require(
            crowdsaleAddress == address(0),
            "TokenVesting: crowdsale already set"
        );
        crowdsaleAddress = _crowdsaleAddress;
        emit SetCrowdsale(_crowdsaleAddress);
    }

    /**
     * @dev Add a new purchased _value of tokens.
     * onlyCrowdsale protected.
     * @param _to vesting address
     * @param _value amount to be vested
     */
    function vest(
        address _to,
        uint256 _value
    ) external onlyCrowdsale {
        //require(
        //    _to != address(0),
        //    "TokenVesting: invalid zero address for beneficiary!"
        //);
        //require(_value > 0, "TokensVesting: invalid value for beneficiary!");
        require(
            totalVesting +_value <= totalLimit,
            "TokenVesting: total value exceeds total limit!"
        );
        
        vests[_to].value += _value;

        totalVesting = totalVesting + _value;

        emit NewVest(_msgSender(), _to, _value);
    }

    /**
     * @dev Start vesting period.
     * Only crowdsale. Will be called once the sale is completed.
     * onlyCrowdsale protected.
     * @param _start start time of vesting
     */
    function startVesting(uint256 _start) public onlyCrowdsale {
        require(finish == 0, "TokenVesting: already started!");
        start = _start;
        finish = _start + finishOfVest;
    }

    /**
     * @dev Calculate amount of already vested tokens.
     * Can also return the amount of unlocked vested tokens.
     * For external use only.
     * @param _holder user address
     * @param _unlocked full vested amount or only the unlocked amount?
     * @return total amount of vested tokens including (unlocked == false) or excluding (unlocked == true) claimed ones 
     */
    function vestedTokens(address _holder, bool _unlocked)
        external
        view
        returns (uint256)
    {
        if (start == 0) {
            return 0;
        }

        Vest memory vested = vests[_holder];
        if (vested.value == 0) {
            return 0;
        }
        uint256 vestedAmount = calculateVestedTokens(vested);
        if (_unlocked)
            return vestedAmount - vested.transferred;

        return vestedAmount;
    }

    /**
     * @dev Calculate amount of already vested tokens.
     * Return full _vested.value if vesting period is finished.
     * For internal use only.
     * @param _vested data struct containing vesting information
     * @return total amount of vested tokens including claimed ones
     */
    function calculateVestedTokens(Vest memory _vested)
        private
        view
        returns (uint256)
    {
        if (block.timestamp >= finish) {
            return _vested.value;
        }

        if (start > block.timestamp)
            return 0;
        // 40% are initially unlocked right away
        uint256 initialUnlock = 2;
        uint256 timePassedAfterStart = block.timestamp - start;
        // Consider initial unlock (availableReleases <= 5)
        uint256 availableReleases = timePassedAfterStart / duration + initialUnlock;
        // RELEASES = 3 -> 5 releases in total
        return availableReleases * _vested.value / (RELEASES + initialUnlock);
    }

    /**
     * @dev Countdown to be displayed on frontend. 
     * Returns next vesting timestamp if nothing is transferrable, else 0 (transferrable amount is unlocked).
     * @param _holder user address
     * @return 0 if unlocked, else timestamp when locked
     */
    function countdown(address _holder) external view returns (uint256){
        if (block.timestamp >= finish) {
            return 0;
        }
        Vest storage vested = vests[_holder];
        // check vested amount, if greater 0, vesting is still unlocked
        uint256 vestedAmount = calculateVestedTokens(vested);
        uint256 transferable = vestedAmount - vested.transferred;
        if (transferable > 0) {
            return 0;
        }
        // compute available releases and passed time
        uint256 timePassedAfterStart = block.timestamp - start;
        uint256 availableReleases = timePassedAfterStart / duration;
        // return unlock timestamp in unix time
        return start + (duration * (availableReleases + 1));
    }

    /**
     * @dev Claim vested tokens. 
     * Returns if nothing to vest or nothing is unlocked. 
     * nonReentrant protected.
     */
    function unlockVestedTokens() external nonReentrant {
        require(start != 0, "vesting: not started yet");
        Vest storage vested = vests[_msgSender()];
        require(vested.value != 0, "vesting: no tokens to vest");

        uint256 vestedAmount = calculateVestedTokens(vested);
        if (vestedAmount == 0) {
            return;
        }

        uint256 transferable = vestedAmount - vested.transferred;
        if (transferable == 0) {
            return;
        }

        vested.transferred = vested.transferred + transferable;
        totalVesting = totalVesting - transferable;
        token.safeTransfer(_msgSender(), transferable);

        emit UnlockVest(_msgSender(), transferable);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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