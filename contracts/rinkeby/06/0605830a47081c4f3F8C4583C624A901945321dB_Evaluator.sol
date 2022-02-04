pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./ERC20TD.sol";
import "./IExerciceSolution.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./BouncerProxy.sol";

contract Evaluator {

    mapping(address => bool) public teachers;
    ERC20TD TDERC20;
   
    mapping(address => mapping(uint256 => bool)) public exerciceProgression;
    mapping(address => IExerciceSolution) public studentExerciceSolution;
    mapping(address => bool) public hasBeenPaired;

    bytes32[20] private randomBytes32ToSign;
    bytes[20] private associatedSignatures;
    uint public nextValueStoreRank;
    mapping(bytes32 => bool) public signedBytes32;
    address payable public referenceBouncerProxy;

    event constructedCorrectly(address erc20Address, address referenceBouncerProxy);
    event UpdateWhitelist(address _account, bool _value);
    event newRandomBytes32AndSig(bytes32 data, bytes sig);

    constructor(ERC20TD _TDERC20, address payable _referenceBouncerProxy) 
    public 
    {
        TDERC20 = _TDERC20;
        referenceBouncerProxy = _referenceBouncerProxy;
        emit constructedCorrectly(address(TDERC20), referenceBouncerProxy);
    }

    fallback () external payable 
    {}

    receive () external payable 
    {}

    function ex1_testERC721()
    public  
    {
        // Checking a solution was submitted
        require(exerciceProgression[msg.sender][0], "No solution submitted");

        // Retrieve ERC721 address from ExerciceSolution
        address studentERC721Address = studentExerciceSolution[msg.sender].ERC721Address();
        IERC721 studentERC721 = IERC721(studentERC721Address);

        // Check they are two different contracts 
        require(studentERC721Address != address(studentExerciceSolution[msg.sender]), "ERC721 and minter are the same");

        // Checking balance pre minting
        uint256 evaluatorBalancePreMint = studentERC721.balanceOf(address(this));
        uint256 minterBalancePreMint = studentERC721.balanceOf(address(studentExerciceSolution[msg.sender]));

        // Claim a token through minter
        uint256 newToken = studentExerciceSolution[msg.sender].mintATokenForMe();

        // Checking balance post minting
        uint256 evaluatorBalancePostMint = studentERC721.balanceOf(address(this));
        uint256 minterBalancePostMint = studentERC721.balanceOf(address(studentExerciceSolution[msg.sender]));

        // Check that token 1 belongs to the Evaluator
        require(evaluatorBalancePostMint == evaluatorBalancePreMint + 1, "Did not receive one token");
        require(studentERC721.ownerOf(newToken) == address(this), "New token does not belong to meeee");

        // Check the token was minted, not lazily transferred
        require(minterBalancePostMint == minterBalancePreMint, "Minter balance changed, did not mint");

        // Check that token 1 can be transferred back to msg.sender, so it's a real ERC721
        uint256 senderBalancePreTransfer = studentERC721.balanceOf(msg.sender);
        studentERC721.safeTransferFrom(address(this), msg.sender, newToken);
        require(studentERC721.balanceOf(address(this)) == evaluatorBalancePreMint, "Balance did not decrease after transfer");
        require(studentERC721.ownerOf(newToken) == msg.sender, "Token does not belong to you");
        require(studentERC721.balanceOf(msg.sender) == senderBalancePreTransfer + 1, "Balance did not increase after transfer");

        // Crediting points
        if (!exerciceProgression[msg.sender][1])
        {
            exerciceProgression[msg.sender][1] = true;
            // ERC721 points
            TDERC20.distributeTokens(msg.sender, 2);
        }
    }

    function ex2_generateASignature(bytes memory _signature) 
    public 
    {
        bytes32 stringToSignToGetPoint = 0x00000000596f75206e65656420746f207369676e207468697320737472696e67;

        // If tx fails here, it means the transaction did not receive a valid signature
        address signatureSender = extractAddress(stringToSignToGetPoint , _signature);
        require(tx.origin == signatureSender, "signature does not match tx originator");

        // Crediting points
        if (!exerciceProgression[msg.sender][2])
        {
            exerciceProgression[msg.sender][2] = true;
            // ERC721 points
            TDERC20.distributeTokens(msg.sender, 2);
        }
    }

    function ex3_extractAddressFromSignature() 
    public 
    {        
        // Retrieving a random signature and associated address
        address signatureSender = extractAddress(randomBytes32ToSign[nextValueStoreRank] , associatedSignatures[nextValueStoreRank]);

        // Checking that student contract is able to extract the address from the signature
        address retrievedAddressByExerciceSolution = studentExerciceSolution[msg.sender].getAddressFromSignature(randomBytes32ToSign[nextValueStoreRank] , associatedSignatures[nextValueStoreRank]);
        
        require(signatureSender == retrievedAddressByExerciceSolution, "Signature not interpreted correctly");
        
        // Incrementing next value store rank
        nextValueStoreRank += 1;
        if (nextValueStoreRank >= 20)
        {
            nextValueStoreRank = 0;
        }

        // Crediting points
        if (!exerciceProgression[msg.sender][3])
        {
            exerciceProgression[msg.sender][3] = true;
            // ERC721 points
            TDERC20.distributeTokens(msg.sender, 2);
        }
    }

    function ex4_manageWhiteListWithSignature(bytes32 _aBytes32YouChose, bytes memory _theAssociatedSignature)
    public
    {
        // Is your signature correctly formated
        address signatureSender = extractAddress(_aBytes32YouChose , _theAssociatedSignature);
        // Broadcaster is signer 
        require(signatureSender == tx.origin, "signature does not match tx originator");

        // Is the signer whitelisted
        require(studentExerciceSolution[msg.sender].whitelist(signatureSender), "originator not whitelisted");
        require(studentExerciceSolution[msg.sender].signerIsWhitelisted(_aBytes32YouChose, _theAssociatedSignature), "Signature not validated correctly");

        // Extracting a random signer
        address storedSignatureSender = extractAddress(randomBytes32ToSign[nextValueStoreRank] , associatedSignatures[nextValueStoreRank]);

        // Is a random signer whitelisted whitelisted
        require(!studentExerciceSolution[msg.sender].whitelist(storedSignatureSender), "Random signer is whitelisted");
        require(!studentExerciceSolution[msg.sender].signerIsWhitelisted(randomBytes32ToSign[nextValueStoreRank] , associatedSignatures[nextValueStoreRank]), "Random signature works");
        
        // Incrementing next value store rank
        nextValueStoreRank += 1;
        if (nextValueStoreRank >= 20)
        {
            nextValueStoreRank = 0;
        }
        // Crediting points
        if (!exerciceProgression[msg.sender][4])
        {
            exerciceProgression[msg.sender][4] = true;
            // ERC721 points
            TDERC20.distributeTokens(msg.sender, 2);
        }
    }

    function ex5_mintATokenWithASpecificSignature(bytes memory _theRequiredSignature)
    public
    {

        // Retrieve ERC721 address from ExerciceSolution
        address studentERC721Address = studentExerciceSolution[msg.sender].ERC721Address();
        IERC721 studentERC721 = IERC721(studentERC721Address);

        // Generating the data that needs to be signed to claim a token on student contract.
        // We hash the concatenation of the evaluator address, the sender's address, and the ERC721 address
        bytes32 dataToSign = keccak256(abi.encodePacked(address(this), tx.origin, studentERC721Address));

        // Has sender signed the correct piece of data, and extract the address
        address signatureSender = extractAddress(dataToSign , _theRequiredSignature);

        // Broadcaster is signer 
        require(signatureSender == tx.origin, "signature does not match tx originator");

        // Checking that we own no NFT before claiming
        uint256 evaluatorBalancePreMint = studentERC721.balanceOf(address(this));

        // Claim a token through minter
        uint256 newToken = studentExerciceSolution[msg.sender].mintATokenForMeWithASignature(_theRequiredSignature);

        // Checking balance post minting
        uint256 evaluatorBalancePostMint = studentERC721.balanceOf(address(this));

        // Check that token 1 belongs to the Evaluator
        require(evaluatorBalancePostMint == evaluatorBalancePreMint + 1, "Did not receive one token");
        require(studentERC721.ownerOf(newToken) == address(this), "New token does not belong to meeee");

        // Incrementing next value store rank
        nextValueStoreRank += 1;
        if (nextValueStoreRank >= 20)
        {
            nextValueStoreRank = 0;
        }
        // Crediting points
        if (!exerciceProgression[msg.sender][5])
        {
            exerciceProgression[msg.sender][5] = true;
            // ERC721 points
            TDERC20.distributeTokens(msg.sender, 3);
        }
    }

    function ex6_deployBouncerProxyAndWhitelistYourself(address payable myBouncerProxy)
    public
    {
        // Build bouncer proxy
        BouncerProxy localBouncer = BouncerProxy(myBouncerProxy);
        // Retrieving your contract code hash
        bytes32 codeHash;
        assembly { codeHash := extcodehash(myBouncerProxy) }
        // Checking it is the correct code hash
        bytes32 referenceCodeHash;
        address _referenceBouncerProxy = referenceBouncerProxy;
        assembly { referenceCodeHash := extcodehash(_referenceBouncerProxy) }

        require(referenceCodeHash == codeHash, "Deployed code is different from reference");

        // Check if sender is whitelisted
        require(localBouncer.whitelist(tx.origin), "Tx originator is not whitelisted");
        // For fun, whitelist sender also
        require(localBouncer.whitelist(msg.sender), "Message sender is not whitelisted");

        // Crediting points
        if (!exerciceProgression[msg.sender][6])
        {
            exerciceProgression[msg.sender][6] = true;
            // ERC721 points
            TDERC20.distributeTokens(msg.sender, 3);
        }
    }

    function ex7_useBouncerProxyToCallEvaluator()
    public
    {
    
        // Retrieving caller contract code hash
        bytes32 codeHash;
        address _sender = msg.sender;
        assembly { codeHash := extcodehash(_sender) }
        // Checking it is the correct code hash
        bytes32 referenceCodeHash;
        address _referenceBouncerProxy = referenceBouncerProxy;
        assembly { referenceCodeHash := extcodehash(_referenceBouncerProxy) }

        require(referenceCodeHash == codeHash, "Deployed code is different from reference");

        // Build bouncer proxy
        BouncerProxy localBouncer = BouncerProxy(msg.sender);
        // Check if sender is whitelisted
        require(!localBouncer.whitelist(tx.origin), "Tx originator is whitelisted");

        // Crediting points
        if (!exerciceProgression[msg.sender][7])
        {
            exerciceProgression[msg.sender][7] = true;
            // ERC721 points
            TDERC20.distributeTokens(msg.sender, 4);
        }
    }

    modifier onlyTeachers() 
    {

        require(TDERC20.teachers(msg.sender));
        _;
    }

    /* Internal functions and modifiers */ 
    function submitExercice(IExerciceSolution studentExercice)
    public
    {
        // Checking this contract was not used by another group before
        require(!hasBeenPaired[address(studentExercice)]);

        // Assigning passed ERC20 as student ERC20
        studentExerciceSolution[msg.sender] = studentExercice;
        hasBeenPaired[address(studentExercice)] = true;

        if (!exerciceProgression[msg.sender][0])
        {
            exerciceProgression[msg.sender][0] = true;
            // setup points
            TDERC20.distributeTokens(msg.sender, 2);
        }
    }

    function setRandomBytes32AndSignature(bytes32[20] memory _randomData, bytes[20] memory _signatures) 
    public 
    onlyTeachers
    {
        randomBytes32ToSign = _randomData;
        associatedSignatures = _signatures;
        nextValueStoreRank = 0;
        for (uint i = 0; i < 20; i++)
        {
            emit newRandomBytes32AndSig(randomBytes32ToSign[i], associatedSignatures[i]);
        }
    }

    function _compareStrings(string memory a, string memory b) 
    internal 
    pure 
    returns (bool) 
    {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function bytes32ToString(bytes32 _bytes32) 
    public 
    pure returns (string memory) 
    {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function extractAddress(bytes32 _hash, bytes memory _signature) 
    internal 
    pure 
    returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Check the signature length
        if (_signature.length != 65) {
            return address(0);
        }
        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
                ), v, r, s);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity ^0.6.0;


interface IExerciceSolution
{
	function ERC721Address() external returns (address);

	function mintATokenForMe() external returns (uint256);

	function mintATokenForMeWithASignature(bytes calldata _signature) external returns (uint256);

	function getAddressFromSignature(bytes32 _hash, bytes calldata _signature) external returns (address);

	function signerIsWhitelisted(bytes32 _hash, bytes calldata _signature) external returns (bool);

	function whitelist(address _signer) external returns (bool);
 
}

pragma solidity ^0.6.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20TD is ERC20 {

mapping(address => bool) public teachers;
event DenyTransfer(address recipient, uint256 amount);
event DenyTransferFrom(address sender, address recipient, uint256 amount);

constructor(string memory name, string memory symbol,uint256 initialSupply) public ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        teachers[msg.sender] = true;
    }

function distributeTokens(address tokenReceiver, uint256 amount) 
public
onlyTeachers
{
	uint256 decimals = decimals();
	uint256 multiplicator = 10**decimals;
  _mint(tokenReceiver, amount * multiplicator);
}

function setTeacher(address teacherAddress, bool isTeacher) 
public
onlyTeachers
{
  teachers[teacherAddress] = isTeacher;
}

modifier onlyTeachers() {

    require(teachers[msg.sender]);
    _;
  }

function transfer(address recipient, uint256 amount) public override returns (bool) {
	emit DenyTransfer(recipient, amount);
        return false;
    }

function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
  emit DenyTransferFrom(sender, recipient, amount);
        return false;
    }

}

pragma solidity ^0.6.0;

/*
  Bouncer identity proxy that executes meta transactions for etherless accounts.
  Purpose:
  I wanted a way for etherless accounts to transact with the blockchain through an identity proxy without paying gas.
  I'm sure there are many examples of something like this already deployed that work a lot better, this is just me learning.
    (I would love feedback: https://twitter.com/austingriffith)
  1) An etherless account crafts a meta transaction and signs it
  2) A (properly incentivized) relay account submits the transaction to the BouncerProxy and pays the gas
  3) If the meta transaction is valid AND the etherless account is a valid 'Bouncer', the transaction is executed
      (and the sender is paid in arbitrary tokens from the signer)
  Inspired by:
    @avsa - https://www.youtube.com/watch?v=qF2lhJzngto found this later: https://github.com/status-im/contracts/blob/73-economic-abstraction/contracts/identity/IdentityGasRelay.sol
    @mattgcondon - https://twitter.com/mattgcondon/status/1022287545139449856 && https://twitter.com/mattgcondon/status/1021984009428107264
    @owocki - https://twitter.com/owocki/status/1021859962882908160
    @danfinlay - https://twitter.com/danfinlay/status/1022271384938983424
    @PhABCD - https://twitter.com/PhABCD/status/1021974772786319361
    gnosis-safe
    uport-identity
*/


//use case 1:
//you deploy the bouncer proxy and use it as a standard identity for your own etherless accounts
//  (multiple devices you don't want to store eth on or move private keys to will need to be added as Bouncers)
//you run your own relayer and the rewardToken is 0

//use case 2:
//you deploy the bouncer proxy and use it as a standard identity for your own etherless accounts
//  (multiple devices you don't want to store eth on or move private keys to will need to be added as Bouncers)
//  a community if relayers are incentivized by the rewardToken to pay the gas to run your transactions for you
//SEE: universal logins via @avsa

//use case 3:
//you deploy the bouncer proxy and use it to let third parties submit transactions as a standard identity
//  (multiple developer accounts will need to be added as Bouncers to 'whitelist' them to make meta transactions)
//you run your own relayer and pay for all of their transactions, revoking any bad actors if needed
//SEE: GitCoin (via @owocki) wants to pay for some of the initial transactions of their Developers to lower the barrier to entry

//use case 4:
//you deploy the bouncer proxy and use it to let third parties submit transactions as a standard identity
//  (multiple developer accounts will need to be added as Bouncers to 'whitelist' them to make meta transactions)
//you run your own relayer and pay for all of their transactions, revoking any bad actors if needed

contract BouncerProxy {

    //to avoid replay
    mapping(address => uint) public nonce;

    // allow for third party metatx account to make transactions through this
    // contract like an identity but make sure the owner has whitelisted the tx
    mapping(address => bool) public whitelist;

    event UpdateWhitelist(address _account, bool _value);
    // copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
    event Received (address indexed sender, uint value);
    // when some frontends see that a tx is made from a bouncerproxy, they may want to parse through these events to find out who the signer was etc
    event Forwarded (bytes sig, address signer, address destination, uint value, bytes data, bytes32 _hash);

    //whitelist the deployer so they can whitelist others
    constructor() 
    public 
    {
        whitelist[msg.sender] = true;
    }

    fallback () external payable 
    {
        emit Received(msg.sender, msg.value); 
    }

    receive () external payable 
    {
        emit Received(msg.sender, msg.value); 
    }

    function updateWhitelist(address _account, bool _value) 
    public 
    returns(bool) 
    {
        require(whitelist[msg.sender],"BouncerProxy::updateWhitelist Account Not Whitelisted");
        whitelist[_account] = _value;
        UpdateWhitelist(_account,_value);
        return true;
    }


    function getHash(address signer, address destination, uint value, bytes memory data) 
    public 
    view 
    returns(bytes32)
    {
        return keccak256(abi.encodePacked(address(this), signer, destination, value, data, nonce[signer]));
    }


    // original forward function copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
    function forward(bytes memory sig, address signer, address destination, uint value, bytes memory data) 
    public 
    {
      //the hash contains all of the information about the meta transaction to be called
      bytes32 _hash = getHash(signer, destination, value, data);
      //increment the hash so this tx can't run again
      nonce[signer]++;
      //this makes sure signer signed correctly AND signer is a valid bouncer
      require(signerIsWhitelisted(_hash,sig),"BouncerProxy::forward Signer is not whitelisted");

      //execute the transaction with all the given parameters
      require(executeCall(gasleft(),destination, value, data));
      emit Forwarded(sig, signer, destination, value, data, _hash);
    }

  // copied from https://github.com/uport-project/uport-identity/blob/develop/contracts/Proxy.sol
  // which was copied from GnosisSafe
  // https://github.com/gnosis/gnosis-safe-contracts/blob/master/contracts/GnosisSafe.sol
    function executeCall(uint gasLimit, address to, uint256 value, bytes memory data) 
    internal 
    returns (bool success) 
    {
    assembly {
               success := call(gasLimit, to, value, add(data, 0x20), mload(data), 0, 0)
            }
    }

  //borrowed from OpenZeppelin's ESDA stuff:
  //https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/cryptography/ECDSA.sol
    function signerIsWhitelisted(bytes32 _hash, bytes memory _signature) 
    internal 
    view 
    returns (bool)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        // Check the signature length
        if (_signature.length != 65) 
        {
          return false;
        }
        // Divide the signature in r, s and v variables
        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solium-disable-next-line security/no-inline-assembly
        assembly {
          r := mload(add(_signature, 32))
          s := mload(add(_signature, 64))
          v := byte(0, mload(add(_signature, 96)))
        }
        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) 
        {
          v += 27;
        }
        // If the version is correct return the signer address
        if (v != 27 && v != 28) 
        {
          return false;
        } else {
          // solium-disable-next-line arg-overflow
          return whitelist[ecrecover(keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
          ), v, r, s)];
        }
    }
}