/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
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
        return
        functionCallWithValue(
            target,
            data,
            value,
            "Address: low-level call with value failed"
        );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
    {
        return
        functionStaticCall(
            target,
            data,
            "Address: low-level static call failed"
        );
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
    {
        return
        functionDelegateCall(
            target,
            data,
            "Address: low-level delegate call failed"
        );
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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
     * by making the `nonReentrant` function external, and make it call a
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId)
    external
    view
    returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface ITheStolenGenerator {
    struct FactionImage{
        bool fillFaction;
        bool fillOwner;
        bool fillHighscore;
        uint16 member;
        string factionName;
        address owner;
        uint256 highscore;
        uint256 factionSteals;
        uint256 steals;
        uint256 current;
    }

    function factionTokenURI(FactionImage memory tokenData)
    external
    view
    returns (string memory);

    function flagTokenURI(string memory factionName, uint current)
    external
    view
    returns (string memory);
}

contract TheStolen is
Ownable,
ERC165,
IERC721,
IERC721Metadata,
ReentrancyGuard
{
    using Address for address;

    //Image Generator
    ITheStolenGenerator stolenImage;

    //FactionToken Ownership
    struct FactionToken {
        address owner;
        uint16 factionId;
        bytes1 isRogue;
        bytes1 isBurned;
    }

    //Flag Ownership
    struct Flag {
        address owner;
        uint16 factionId;
        bytes1 vulnerable;
        bytes1 withoutFaction;
    }

    //Address ID Data
    struct AddressID {
        uint16 factionId;
        uint16 factionTokenId;
        uint16 factionLastTokenId;
        uint8 factionBalance;
        bytes1 hasMinted;
    }

    //Address Data
    struct AddressData {
        bytes1 hasRogue;
        bytes1 hasFlag;
        bytes1 withoutFaction;
        uint16 rogueId;
        uint256 stolen;
        uint256 switchedFaction;
    }

    //Faction ID Data
    struct FactionID {
        uint16 factionId;
        uint16 memberCount;
        string name;
    }

    //Faction Data
    struct FactionData {
        uint256 stolen;
        uint256 currentHoldtime;
        uint256 highscore;
    }

    //Faction Name ID
    struct FactionNameId {
        uint16 factionId;
        address contractAddress;
    }

    uint256 private _mintStarttime = 1;
    uint256 private _mintTime = 1;

    bytes1 private _locked = 0x00;
    bytes1 private _open = 0x00;

    uint16 private _currentIndex = 1;
    uint16 private _burnedCount = 0;
    uint16 private _currentFactionIndex = 1;

    uint256 private _flagLastTransferTime = 1;

    uint16 private _currentFactionHolding;

    uint16 private _currentLeader;
    uint256 private _currentLongestHoldtime;

    uint16 internal immutable _flagStealTime;
    uint16 internal immutable _flagFastStealTime;

    uint16 internal immutable collectionSize;
    uint8 internal immutable maxBatchSize;

    uint256 internal immutable mintPrice;
    uint256 internal flagPrice;

    //All Addresses that have been entitled to a free mint
    mapping(address => bytes1) private freeMintList;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    //THE FLAG
    Flag private _flag;

    // Mapping from token ID to ownership
    mapping(uint16 => FactionToken) private _factionOwnerships;

    // Mapping owner address to address ID and data
    mapping(address => AddressID) private _addressIDs;
    mapping(address => AddressData) private _addressData;

    // Mapping from factionId to faction ID and data
    mapping(uint16 => FactionID) private _factionIDs;
    mapping(uint16 => FactionData) private _factionData;
    // Mapping from factionName to faction name ID
    mapping(string => FactionNameId) private _factionNameId;

    // Mapping from token ID to approved address
    mapping(uint16 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event GotStolen(address from, address to);
    event GotFlag(address from, address to);
    event MintedFlag(address to);
    event NewLeader(uint16 prevLeader, uint16 newLeader);
    event NewFactionHolding(uint16 newHolding);
    event Merge(address owner, uint256 oldTokenId);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxBatchSize_,
        uint256 collectionSize_
    ) {
        require(collectionSize_ > 0, "collection must have a nonzero supply");
        require(maxBatchSize_ > 0, "max batch size must be nonzero");

        _name = name_;
        _symbol = symbol_;
        maxBatchSize = uint8(maxBatchSize_ + 1);
        collectionSize = uint16(collectionSize_ + 1);

        mintPrice = 0.00 ether;
        flagPrice = 0.00 ether;

        _mintTime = 600;

        _flagStealTime = 21600;
        _flagFastStealTime = 600;
    }

    //Set the Contract for image generation if mint not started and not locked
    function setImageContract(address imageContract) private {
        require(_open != 0x01 && _locked != 0x01, "contract open or locked");
        stolenImage = ITheStolenGenerator(imageContract);
    }

    ///////////////////////////////////////////////////
    // MODIFIER

    modifier isOpen() {
        require(_open == 0x01, "mint not open.");
        _;
    }

    modifier unlocked(uint8 quantity) {
        require(
            _locked != 0x01 &&
            _currentIndex + quantity < collectionSize + 1 &&
            block.timestamp < _mintStarttime + _mintTime,
            "still unlocked"
        );
        _;
    }

    modifier locked() {
        require(
            _locked == 0x01 ||
            _currentIndex == collectionSize - 1 ||
            block.timestamp > _mintStarttime + _mintTime,
            "still unlocked"
        );
        _;
    }

    // MODIFIER
    ///////////////////////////////////////////////////

    ///////////////////////////////////////////////////
    // PUBLIC VIEW

    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
    {
        bytes4 _ERC165_ = 0x01ffc9a7;
        bytes4 _ERC721_ = 0x80ac58cd;
        bytes4 _ERC721Metadata_ = 0x5b5e139f;
        return
        interfaceId == _ERC165_ ||
        interfaceId == _ERC721_ ||
        interfaceId == _ERC721Metadata_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return (_currentIndex - _burnedCount);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "balance query for the zero address");
        return uint256(_addressIDs[owner].factionBalance);
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_existed(uint16(tokenId)), "nonexistent token");
        if (tokenId == 0) {
            if (flagReleased()) {
                return _flag.owner;
            }
        }
        return _ownershipOf(uint16(tokenId)).owner;
    }

    function exists(uint16 tokenId) public view returns (bool) {
        return _existed(tokenId) && !_burned(tokenId);
    }

    function burned(uint16 tokenId) public view returns (bool) {
        return _burned(tokenId);
    }

    ///////////////////////////////////////////////////

    function hasOneFreeMint() public view returns (bool) {
        return freeMintList[msg.sender] == 0x01;
    }

    function factionMintCost() public view returns (uint256) {
        return mintPrice;
    }

    function flagReleased() public view returns (bool) {
        return (_locked == 0x01 ||
        _currentIndex == collectionSize ||
        block.timestamp > _mintStarttime + _mintTime);
    }

    function flagMintPrice() public view returns (uint256) {
        return (flagPrice * 11)/10;
    }

    ///////////////////////////////////////////////////

    function getAddressData(address a)
    public
    view
    returns (AddressID memory, AddressData memory)
    {
        return (_addressIDs[a], _addressData[a]);
    }

    function getFactionData(uint16 factionId)
    public
    view
    returns (FactionID memory, FactionData memory)
    {
        require(factionId < _currentFactionIndex, "faction doesnt exist");
        return (_factionIDs[factionId], _factionData[factionId]);
    }

    function getTokenData(uint16 tokenId)
    public
    view
    returns (FactionToken memory)
    {
        require(_existed(tokenId), "token doesnt exist");
        return _factionOwnerships[tokenId];
    }

    function getHolderFactionId() public view returns (uint16) {
        require(
            _flag.owner != address(0) && _flag.withoutFaction != 0x01,
            "no faction owns the flag right now."
        );
        return _flag.factionId;
    }

    function getLeaderHoldtime() public view returns (uint256) {
        require(_flagLastTransferTime != 1, "no scores yet");
        Flag memory flag = _flag;

        uint256 currentHolderHoldtime = _factionData[flag.factionId]
        .currentHoldtime + (block.timestamp - _flagLastTransferTime);
        uint256 currentLongestHoldtime = _currentLongestHoldtime;

        if (
            flag.factionId != _currentLeader &&
            currentLongestHoldtime > currentHolderHoldtime
        ) {
            return currentLongestHoldtime;
        } else {
            return currentHolderHoldtime;
        }
    }

    function getLeaderName() public view returns (string memory) {
        require(_flagLastTransferTime != 1, "no scores yet");
        Flag memory flag = _flag;
        uint16 currentLeader = _currentLeader;
        uint256 currentHolderHoldtime = _factionData[flag.factionId]
        .currentHoldtime + (block.timestamp - _flagLastTransferTime);

        if (
            flag.factionId != currentLeader &&
            _currentLongestHoldtime > currentHolderHoldtime
        ) {
            return _factionIDs[currentLeader].name;
        } else {
            return _factionIDs[flag.factionId].name;
        }
    }

    function getCurrentHoldtime() public view returns (uint256) {
        uint16 holderId = _flag.factionId;
        if (_flagLastTransferTime == 1 || _flag.withoutFaction == 0x01) {
            return 0;
        }
        return
        _factionData[holderId].currentHoldtime +
        (block.timestamp - _flagLastTransferTime);
    }

    function validateFactionName(string memory message)
    public
    pure
    returns (bool)
    {
        bytes memory messageBytes = bytes(message);

        // Max length 16, A-Z only
        require(
            messageBytes.length > 2 && messageBytes.length < 17,
            "faction name length unfit"
        );
        require(
            messageBytes[0] != 0x20 &&
            messageBytes[messageBytes.length - 1] != 0x20,
            "Invalid characters"
        );

        for (uint256 i = 0; i < messageBytes.length; i++) {
            bytes1 char = messageBytes[i];
            if (!(char >= 0x41 && char <= 0x5A) || char == 0x20) {
                revert("Invalid character");
            }
        }
        return true;
    }

    // PUBLIC VIEW
    ///////////////////////////////////////////////////

    ///////////////////////////////////////////////////
    // INTERNAL VIEW

    function _ownershipOf(uint16 tokenId, uint16 lowestToCheck)
    internal
    view
    returns (FactionToken memory)
    {
        FactionToken memory ft = _factionOwnerships[tokenId];
        lowestToCheck--;

        for (uint16 curr = tokenId; curr > lowestToCheck; curr--) {
            ft = _factionOwnerships[curr];
            if (ft.isBurned != 0x01 && ft.owner != address(0)) {
                return ft;
            }
        }

        revert("unable to determine the owner of token");
    }

    function _ownershipOf(uint16 tokenId)
    internal
    view
    returns (FactionToken memory)
    {
        FactionToken memory ft = _factionOwnerships[tokenId];
        uint16 lowestToCheck;
        if (tokenId >= maxBatchSize) {
            lowestToCheck = tokenId - maxBatchSize + 1;
        }

        for (uint16 curr = tokenId; curr > lowestToCheck; curr--) {
            ft = _factionOwnerships[curr];
            if (curr > 0 && ft.isBurned != 0x01 && ft.owner != address(0)) {
                return ft;
            }
        }

        revert("unable to determine the owner of token");
    }

    function _existed(uint16 tokenId) internal view returns (bool) {
        if (tokenId == 0) {
            return _flag.owner != address(0);
        } else {
            return tokenId < _currentIndex;
        }
    }

    function _burned(uint16 tokenId) internal view returns (bool) {
        if (tokenId == 0) {
            return _flag.owner == address(0);
        }
        return _factionOwnerships[tokenId].isBurned == 0x01 ? true : false;
    }

    // PUBLIC VIEW
    ///////////////////////////////////////////////////

    ///////////////////////////////////////////////////
    // APPROVAL

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "approve caller is not owner nor approved for all"
        );

        _approve(owner, to, uint16(tokenId));
    }

    function _approve(
        address owner,
        address to,
        uint16 tokenId
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId)
    public
    view
    override
    returns (address)
    {
        uint16 tId = uint16(tokenId);
        require(_existed(tId), "approved query for nonexistent token");
        return _tokenApprovals[tId];
    }

    function setApprovalForAll(address operator, bool approved)
    public
    override
    {
        require(operator != _msgSender(), "approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function _isApprovedOrOwner(address spender, uint16 tokenId)
    internal
    view
    virtual
    returns (address owner, bool isApprovedOrOwner)
    {
        owner = ownerOf(tokenId);

        require(owner != address(0), "nonexistent token");

        isApprovedOrOwner = (spender == owner ||
        _tokenApprovals[tokenId] == spender ||
        isApprovedForAll(owner, spender));
    }

    // APPROVAL
    ///////////////////////////////////////////////////

    ///////////////////////////////////////////////////
    // TRANSFER

    //Either get Flag from previous owner
    //Or Transfer Faction Token
    function _transfer(
        address from,
        address to,
        uint16 tokenId
    ) private {
        require(to != address(0), "transfer to the zero address");
        require(from != to, "transfer to the zero address");

        // Clear approvals from the previous owner

        if (tokenId == 0) {
            Flag memory flag = _flag;

            bool isApprovedOrOwner = (_msgSender() == flag.owner ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(flag.owner, _msgSender()));

            require(
                isApprovedOrOwner,
                "transfer caller is not owner nor approved"
            );

            _approve(flag.owner, address(0), tokenId);

            uint8 chanceForStealing = uint8(
                uint256(
                    keccak256(
                        abi.encodePacked((block.difficulty + block.timestamp))
                    )
                ) % 100
            );
            if (chanceForStealing < 20) {
                _flag.vulnerable = 0x01;
            }
            _getFlag(to, 0x00);
        } else {
            FactionToken memory prevOwnership = _ownershipOf(tokenId);

            bool isApprovedOrOwner = (_msgSender() == prevOwnership.owner ||
            getApproved(tokenId) == _msgSender() ||
            isApprovedForAll(prevOwnership.owner, _msgSender()));

            require(
                isApprovedOrOwner,
                "transfer caller is not owner nor approved"
            );

            _transferFaction(from, to, tokenId, prevOwnership);
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        uint16 tId = uint16(tokenId);
        (, bool isApprovedOrOwner) = _isApprovedOrOwner(_msgSender(), tId);
        require(
            isApprovedOrOwner,
            "ERC721: transfer caller is not owner nor approved"
        );
        _transfer(from, to, tId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        transferFrom(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "transfer to non ERC721Receiver implementer"
        );
    }

    ///////////////////////////////////////////////////

    //Remove Faction Token from previous Owner
    //Add to new Owners wallet, merge accordingly
    function _transferFaction(
        address prevOwner,
        address newOwner,
        uint16 tokenId,
        FactionToken memory ft
    ) private {
        _removeFrom(prevOwner, tokenId, ft);

        emit Transfer(prevOwner, newOwner, tokenId);

        //Read Owner Data
        AddressData memory no = _addressData[newOwner];
        AddressID memory noID = _addressIDs[newOwner];

        //save Time
        if (no.hasFlag == 0x01) {
            _saveOwnerTime();
        }

        //Merge with Existing Rogue Faction Token
        if (no.hasRogue == 0x01) {
            _burn(
                newOwner,
                no.rogueId
            );
            no.hasRogue = 0x00;
        }

        ft.owner = newOwner;

        //if Wallet owns other Faction Token, merge with old Faction token
        if (noID.factionBalance > 0) {
            _burn(
                newOwner,
                noID.factionLastTokenId
            );
            emit Merge(newOwner, noID.factionLastTokenId);
        }

        //set new Rogue Faction Token or Faction Token
        if (noID.factionBalance > 1) {
            noID = _checkNewLast(noID, ft, noID.factionLastTokenId);

            noID.factionBalance--;
            no.hasRogue = 0x01;
            no.rogueId = tokenId;
            ft.isRogue = 0x01;
        } else {
            ft.isRogue = 0x00;
            noID.factionBalance = 1;
            noID.factionId = ft.factionId;
            _factionIDs[ft.factionId].memberCount++;

            noID.factionLastTokenId = tokenId;
            noID.factionTokenId = tokenId;

            if (no.hasFlag == 0x01) {
                (no) = _changeFlagOwner(no, newOwner, 0x00);
            }
        }

        //Write Owner Data and Faction Token Ownership
        _addressIDs[newOwner] = noID;
        _addressData[newOwner] = no;

        _factionOwnerships[tokenId] = ft;
    }

    //Remove from previous owner
    //If wallet owns rogue or no further Faction Token, set wallet state accordingly
    function _removeFrom(
        address prevOwner,
        uint16 tokenId,
        FactionToken memory ft
    ) private {
        //Read previous Owner Data
        AddressData memory po = _addressData[prevOwner];
        AddressID memory poID = _addressIDs[prevOwner];

        _approve(prevOwner, address(0), tokenId);

        //remove from wallet
        if (po.hasRogue == 0x01 && po.rogueId == tokenId) {
            po.hasRogue = 0x00;
        } else {
            poID.factionBalance--;
        }

        //save Time
        if (po.hasFlag == 0x01) {
            _saveOwnerTime();
        }

        //Make Flag Factionless if no further Faction Token exist
        //or set new IDs
        if (poID.factionBalance == 0) {
            _factionIDs[poID.factionId].memberCount--;
            (poID, po) = _checkRogue(poID, po);
            if (po.hasFlag == 0x01) {
                (po) = _changeFlagOwner(po, prevOwner, 0x00);
            }
        } else {
            if (tokenId == poID.factionLastTokenId) {
                poID = _checkNewLast(poID, ft, tokenId);
            } else {
                uint16 nextId = tokenId + 1;
                FactionToken memory ft2 = _factionOwnerships[nextId];
                if (_existed(nextId)) {
                    if (ft2.isBurned != 0x01 && ft2.owner == address(0)) {
                        _factionOwnerships[nextId] = ft;
                    }
                }
            }
            if (tokenId == poID.factionTokenId) {
                poID = _checkNewFirst(poID, ft, tokenId);
            }
        }

        //Write previous Owner Data
        _addressIDs[prevOwner] = poID;
        _addressData[prevOwner] = po;
    }

    //Check For Rogue Faction token in Wallet
    function _checkRogue(AddressID memory ownerID, AddressData memory ownerData)
    private
    returns (AddressID memory oID, AddressData memory o)
    {
        //Initialize Return Variables
        o = ownerData;
        oID = ownerID;

        //If has a Rogue Faction Token, make it new Faction Token
        //else set Factionless
        if (o.hasRogue == 0x01) {
            FactionToken memory r = _ownershipOf(o.rogueId);
            oID.factionId = r.factionId;
            _factionIDs[r.factionId].memberCount++;
            r.isRogue = 0x00;
            _factionOwnerships[o.rogueId] = r;
            oID.factionTokenId = o.rogueId;
            oID.factionLastTokenId = o.rogueId;
            o.rogueId = 0;
        } else {
            o.withoutFaction = 0x01;
            oID.factionLastTokenId = 0;
            oID.factionTokenId = 0;
        }
    }

    function _checkNewLast(
        AddressID memory ownerID,
        FactionToken memory ft,
        uint16 tokenId
    ) private returns (AddressID memory oID) {
        oID = ownerID;
        uint16 prevTokenId = tokenId - 1;
        if (prevTokenId != 0) {
            if (prevTokenId == oID.factionTokenId) {
                oID.factionLastTokenId = prevTokenId;
                return oID;
            }

            FactionToken memory ft2 = _ownershipOf(
                prevTokenId,
                oID.factionTokenId
            );
            if (ft2.isBurned != 0x01 && ft2.owner == address(0)) {
                _factionOwnerships[prevTokenId] = ft;
                oID.factionLastTokenId = prevTokenId;
                return oID;
            } else {
                for (
                    uint16 curr = prevTokenId;
                    curr >= oID.factionTokenId;
                    curr--
                ) {
                    ft2 = _ownershipOf(curr, oID.factionTokenId);
                    if (
                        ft2.isBurned != 0x01 &&
                        (ft2.owner == address(0) || ft2.owner == ft.owner)
                    ) {
                        _factionOwnerships[curr] = ft;
                        oID.factionLastTokenId = curr;
                        return oID;
                    }
                }
            }
        }
        oID.factionLastTokenId = 0;
        oID.factionTokenId = 0;
        return oID;
    }

    function _checkNewFirst(
        AddressID memory ownerID,
        FactionToken memory ft,
        uint16 tokenId
    ) private returns (AddressID memory oID) {
        oID = ownerID;
        uint16 nextTokenId = tokenId + 1;

        if (nextTokenId == oID.factionLastTokenId) {
            oID.factionTokenId = nextTokenId;
            return oID;
        }

        FactionToken memory ft2 = _ownershipOf(nextTokenId, oID.factionTokenId);
        if (ft2.isBurned != 0x01 && ft2.owner == address(0)) {
            _factionOwnerships[nextTokenId] = ft;
            oID.factionTokenId = nextTokenId;
            return oID;
        } else {
            for (
                uint16 curr = nextTokenId;
                curr <= oID.factionLastTokenId;
                curr++
            ) {
                ft2 = _ownershipOf(curr, oID.factionTokenId);
                if (
                    ft2.isBurned != 0x01 &&
                    (ft2.owner == address(0) || ft2.owner == ft.owner)
                ) {
                    _factionOwnerships[curr] = ft;
                    oID.factionTokenId = curr;
                    return oID;
                }
            }
        }
        oID.factionLastTokenId = 0;
        oID.factionTokenId = 0;
        return oID;
    }

    // TRANSFER
    ///////////////////////////////////////////////////

    ///////////////////////////////////////////////////
    // MINT FACTION

    function _addReservedFaction(
        string memory factionName,
        address contractAddress
    ) private {
        require(
            contractAddress != address(0),
            "reserving 0 address not supported."
        );
        _factionNameId[factionName].contractAddress = contractAddress;
        _addToFaction(factionName);
    }

    //Return newly created or existing Faction (reserved restricted access)
    function _addToFaction(string memory factionName) private returns (uint16) {
        validateFactionName(factionName);

        FactionNameId memory factionNameID = _factionNameId[factionName];
        FactionID memory faction;

        if (factionNameID.factionId != 0) {
            _factionIDs[factionNameID.factionId].memberCount++;
            faction = _factionIDs[factionNameID.factionId];
        } else {
            faction = FactionID(_currentFactionIndex, 0, factionName);
            _factionNameId[factionName].factionId = _currentFactionIndex;
            _currentFactionIndex++;
            faction.memberCount++;
            _factionIDs[faction.factionId] = faction;
            if (factionNameID.contractAddress != address(0)) {
                IERC721 c = IERC721(factionNameID.contractAddress);
                require(
                    c.balanceOf(msg.sender) > 0,
                    "must own reserved faction nft"
                );
            }
        }

        return faction.factionId;
    }

    //Mint Quantity Faction Token with Faction Name
    function factionMint(uint8 quantity, string memory factionName)
    external
    payable
    isOpen
    unlocked(quantity)
    {
        require(
            msg.sender != address(0),
            "Mint to the zero address not supported"
        );
        require(msg.sender == tx.origin, "No Bot minting!");

        if (freeMintList[msg.sender] == 0x01) {
            require(
                msg.value == mintPrice * (quantity - 1),
                "invalid mint price"
            );
        } else {
            require(msg.value == mintPrice * quantity, "invalid mint price");
        }

        uint16 factionId = _addToFaction(factionName);

        uint16 startTokenId = _currentIndex;
        uint16 endTokenId = _currentIndex + quantity;

        require(quantity < maxBatchSize, "quantity too high");
        require(
            _addressIDs[msg.sender].hasMinted != 0x01,
            "address already used its chance"
        );

        if(_addressIDs[msg.sender].factionBalance > 0){
            uint16 lastId = _addressIDs[msg.sender].factionLastTokenId;
            _burn(msg.sender,lastId);
            emit Merge(msg.sender, lastId);
        }


        _addressIDs[msg.sender] = AddressID(
            factionId,
            startTokenId,
            endTokenId - 1,
            quantity,
            0x01
        );

        _factionOwnerships[startTokenId] = FactionToken(
            msg.sender,
            factionId,
            0x00,
            0x00
        );

        for (uint16 i = startTokenId; i < endTokenId; i++) {
            emit Transfer(address(0), msg.sender, i);
        }

        _currentIndex = endTokenId;
    }

    // MINT FACTION
    // MINT FLAG

    function flagVulnerable() private view returns (bool) {
        uint256 lastTransfer = _flagLastTransferTime;
        return
        (_flag.vulnerable == 0x01 &&
        lastTransfer + _flagFastStealTime > block.timestamp) ||
        lastTransfer + _flagStealTime < block.timestamp;
    }

    //Mint or Get the Flag
    function huntFlag() external payable locked {
        require(
            msg.sender != address(0),
            "Mint to the zero address not supported"
        );
        require(msg.sender == tx.origin, "No Bot minting!");

        address currentFlagOwner = _flag.owner;

        require(msg.sender != currentFlagOwner, "No Self minting!");

        //If Flag is not stealable
        if (!flagVulnerable()) {
            uint256 currentMintPrice = (flagPrice * 11)/10;

            require(msg.value == currentMintPrice, "invalid get price");
            flagPrice = currentMintPrice;
            //change price

            //If not minting Flag
            if (currentFlagOwner != address(0)) {
                _getFlag(msg.sender, 0x00);
            } else {
                _flagLastTransferTime = block.timestamp;
                _addressData[msg.sender] = _changeFlagOwner(
                    _addressData[msg.sender],
                    msg.sender,
                    0x00
                );

                emit MintedFlag(msg.sender);
            }
        } else {
            _getFlag(msg.sender, 0x01);
        }
    }

    // MINT FLAG
    ///////////////////////////////////////////////////

    ///////////////////////////////////////////////////
    // FLAG TRANSFER

    //save last Owner Score, set new Owner with stolen variable
    function _getFlag(address newOwner, bytes1 stolen) private {
        _saveOwnerTime();
        _flagLastTransferTime = block.timestamp;
        _changeFlagOwner(newOwner, _flag.owner, stolen);
    }

    //save new Score, and if applicable, as Highscore and Leader score.
    //sets current Leader accordingly
    function _saveOwnerTime() private {
        if (_flag.withoutFaction == 0x00 && _flagLastTransferTime != 1) {
            uint16 fof = _flag.factionId;
            uint256 currentHoldtime = _factionData[fof].currentHoldtime +
            (block.timestamp - _flagLastTransferTime);

            _factionData[fof].currentHoldtime = currentHoldtime;

            if (_factionData[fof].highscore < currentHoldtime) {
                _factionData[fof].highscore = currentHoldtime;
                if (currentHoldtime > _currentLongestHoldtime) {
                    _currentLongestHoldtime = currentHoldtime;
                    emit NewLeader(_currentLeader, fof);
                    _currentLeader = fof;
                }
            }
        }
    }

    function _changeFlagOwner(
        AddressData memory newOwnerData,
        address newOwner,
        bytes1 stolen
    ) private returns (AddressData memory no) {
        //Read owner Data
        no = newOwnerData;
        //Write owner Data
        (_addressData[newOwner], _addressData[_flag.owner]) = _changeFlagOwner(
            no,
            newOwner,
            _addressData[_flag.owner],
            _flag.owner,
            stolen
        );
    }

    function _changeFlagOwner(
        address newOwner,
        address prevOwner,
        bytes1 stolen
    ) private {
        //Read owner Data
        AddressData memory no = _addressData[newOwner];
        AddressData memory po = _addressData[prevOwner];
        //Write owner Data
        (_addressData[newOwner], _addressData[prevOwner]) = _changeFlagOwner(
            no,
            newOwner,
            po,
            prevOwner,
            stolen
        );
    }

    function _changeFlagOwner(
        AddressData memory noData,
        address newOwner,
        AddressData memory poData,
        address prevOwner,
        bytes1 stolen
    ) private returns (AddressData memory no, AddressData memory po) {
        //Initialize return Variables
        no = noData;
        po = poData;

        //Read Flag
        Flag memory f = _flag;

        uint16 noIDFactionId = _addressIDs[newOwner].factionId;
        uint16 poIDFactionId = _addressIDs[prevOwner].factionId;

        //remove flag from previous owner if existent
        if (prevOwner != newOwner) {
            if (prevOwner != address(0)) {
                po = _addressData[f.owner];

                po.hasFlag = 0x00;
            }

            emit Transfer(_flag.owner, newOwner, 0);
        }

        //change Flag and Owner Data
        f.factionId = noIDFactionId;
        f.owner = newOwner;
        no.hasFlag = 0x01;
        f.vulnerable == 0x00;

        //if stolen, increase count, emit event
        if (stolen == 0x01) {
            no.stolen++;
            _factionData[poIDFactionId].stolen++;
            emit GotStolen(prevOwner, newOwner);
        } else {
            emit GotFlag(prevOwner, newOwner);
        }

        //if new faction reset timer
        if (noIDFactionId != poIDFactionId) {
            _factionData[poIDFactionId].currentHoldtime = 0;
            _factionData[noIDFactionId].currentHoldtime = 0;
            emit NewFactionHolding(noIDFactionId);
        }

        f.withoutFaction = no.withoutFaction;

        //set current faction holding
        _currentFactionHolding = noIDFactionId;

        //Write Flag
        _flag = f;
    }

    // FLAG TRANSFER
    ///////////////////////////////////////////////////

    ///////////////////////////////////////////////////
    // BURN

    //Burn Faction Token except Flag
    function burn(uint16 tokenId) public {
        require(tokenId > 0, "Shouldn't burn flag");

        FactionToken memory ft = _ownershipOf(tokenId);
        require(
            _existed(tokenId) && ft.isBurned != 0x01,
            "nonexistent or burned token"
        );

        (address owner, bool isApprovedOrOwner) = _isApprovedOrOwner(
            _msgSender(),
            tokenId
        );
        require(isApprovedOrOwner, "caller is not owner nor approved");

        _burn(owner, tokenId, ft);
    }

    //Remove Faction from owner and burn it
    function _burn(
        address owner,
        uint16 tokenId,
        FactionToken memory ft
    ) internal {
        _removeFrom(owner, tokenId, ft);
        emit Transfer(owner, address(0), tokenId);
        _burnedCount++;
        ft.owner = address(0);
        ft.isBurned = 0x01;

        _factionOwnerships[tokenId] = ft;
    }

    //Remove Faction from owner and burn it
    function _burn(
        address owner,
        uint16 tokenId
    ) internal {
        FactionToken memory ft = _factionOwnerships[tokenId];
        _removeFrom(owner, tokenId, ft);
        emit Transfer(owner, address(0), tokenId);
        _burnedCount++;
        ft.owner = address(0);
        ft.isBurned = 0x01;

        _factionOwnerships[tokenId] = ft;
    }

    // BURN
    ///////////////////////////////////////////////////

    ///////////////////////////////////////////////////
    // TOKENURI

    string constant colorActive = "cb0429";
    string constant colorNormal = "000000";

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        if (tokenId == 0) {
            uint16 factionId = _flag.factionId;
            string memory factionName = _flag.withoutFaction != 0x01
            ? _factionIDs[factionId].name
            : "";
            return stolenImage.flagTokenURI(factionName, getCurrentHoldtime());
        } else {
            uint16 tId = uint16(tokenId);
            require(_existed(tId) && !_burned(tId), "nonexistent token");

            uint16 factionId = _ownershipOf(tId).factionId;

            AddressData memory data = _addressData[_ownershipOf(tId).owner];

            FactionData memory fdata = _factionData[factionId];

            ITheStolenGenerator.FactionImage memory factionImageData;
            factionImageData.fillFaction = factionId ==
            _currentFactionHolding &&
            _flag.withoutFaction != 0x01;
            factionImageData.fillOwner = _ownershipOf(tId).owner ==
            _flag.owner &&
            _flag.withoutFaction != 0x01;
            factionImageData.fillHighscore = _currentLeader == factionId;
            factionImageData.factionName = _factionIDs[factionId].name;
            factionImageData.highscore = fdata.highscore;
            factionImageData.member = _factionIDs[factionId].memberCount;
            factionImageData.factionSteals = fdata.stolen;
            factionImageData.steals = data.stolen;
            factionImageData.current = factionId == _currentFactionHolding &&
            _flag.withoutFaction != 0x01
            ? getCurrentHoldtime()
            : 0;

            return stolenImage.factionTokenURI(factionImageData);
        }
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    // TOKENURI
    ///////////////////////////////////////////////////

    ///////////////////////////////////////////////////
    // OWNER FUNCTIONS

    function collectFees() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function addFreeAdresses(address[] memory addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            freeMintList[addresses[i]] = 0x01;
        }
    }

    function lockFactionMint() external onlyOwner {
        _locked = 0x01;
    }

    function startFactionMint(address imageContract) external onlyOwner {
        setImageContract(imageContract);
        _mintStarttime = block.timestamp;
        _open = 0x01;
    }

    // OWNER FUNCTIONS
    ///////////////////////////////////////////////////

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
            IERC721Receiver(to).onERC721Received(
                _msgSender(),
                from,
                tokenId,
                _data
            )
            returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                    "ERC721V: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}