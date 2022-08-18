/**
 *Submitted for verification at Etherscan.io on 2022-08-17
*/

// SPDX-License-Identifier: MIT

/**
 * @title BrokerDefi Partner tokens
 * author : saad sarwar
 */

pragma solidity ^0.8.4;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
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
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {

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

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

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
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;

    string private _symbol;

    mapping(uint256 => address) private _owners;

    mapping(address => uint256) private _balances;

    mapping(uint256 => address) private _tokenApprovals;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
    interfaceId == type(IERC721Metadata).interfaceId ||
    super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;

        _status = _NOT_ENTERED;
    }
}

interface IBrokerDefiPriceConsumer {
    function getPartnerPriceInEth() external view returns(uint);
}

contract BrokerDefiPartner is ERC721, Ownable, ReentrancyGuard {

    uint public TOKEN_ID = 0; // starts from one

    address public BROKER_DEFI_PRICE_CONSUMER = 0xd16e37A0D7EF673feFD6b6359E4108b31B710856;

    uint public MAX_PER_TRX = 10;

    uint public ALLOCATED_FOR_TEAM = 250;

    uint public TEAM_COUNT;

    bool public ESCROW_ALLOWED = true;

    uint256 public MAX_SUPPLY = 2500; // max supply of nfts

    bool public saleIsActive = true; // to control public sale

    address payable public treasury = payable(0xA86B7feF6cD21ED65eD3D2AE55118cd436C58C66);

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // mapping for tokenId to current escrow period if token is in escrow
    mapping(uint256 => uint256) public escrowedAt;

    // mapping for tokenId to total escrow period, doesn't include the escrow period
    mapping(uint256 => uint256) public escrowPeriod;

    // mapping for tokenIds to partner codes
    mapping(uint256 => uint256) public partnerCodes;

    // mapping for partner codes to partner code usage count
    mapping(uint256 => uint256) public partnerCodesCount;

    // mapping for partner codes to token ids
    mapping(uint256 => uint256) public codeOwners;

    // additional mapping for partner codes verification for easy one step code check
    mapping(uint256 => bool) public partnerCodesVerification;

    uint public PARTNER_COMMISSION = 20;

    uint public PARTNER_DISCOUNT = 10;

    string public baseTokenURI = "https://brokerdefi.io/api/v1/metadata-partner/";

    constructor() ERC721("BrokerDeFi Partner", "BDPT") {}

    function setPriceConsumer(address priceConsumer) public onlyOwner() {
        BROKER_DEFI_PRICE_CONSUMER = priceConsumer;
    }

    function setPartnerCommission(uint commission) public onlyOwner() {
        PARTNER_COMMISSION = commission;
    }

    function setPartnerDiscount(uint discount) public onlyOwner() {
        PARTNER_DISCOUNT = discount;
    }

    function allowEscrow(bool allow) public onlyOwner() {
        ESCROW_ALLOWED = allow;
    }

    function changeTreasuryAddress(address payable _newTreasuryAddress) public onlyOwner() {
        treasury = _newTreasuryAddress;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner() {
        baseTokenURI = _newBaseURI;
    }

    // function to set a particular token uri manually if something incorrect in one of the metadata files
    function setTokenURI(uint tokenID, string memory uri) public onlyOwner() {
        _tokenURIs[tokenID] = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            return _tokenURIs[tokenId];
        }
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setMaxPerTrx(uint maxPerTrx) public onlyOwner {
        MAX_PER_TRX = maxPerTrx;
    }

    // code is actually just a six digit number and it will be public so people can distribute their code to others,
    function setCode(uint tokenId) private {
        uint code = (block.timestamp + tokenId) % 100000;
        partnerCodes[tokenId] = code;
        partnerCodesVerification[code] = true;
        codeOwners[code] = tokenId;
    }

    function getTotalEscrowPeriod(uint tokenId) public view returns(uint) {
        return (block.timestamp - escrowedAt[tokenId]) + escrowPeriod[tokenId];
    }

    function escrow(uint tokenId) public {
        require(ESCROW_ALLOWED, "escrow not allowed");
        require(ERC721._exists(tokenId), "escrowing non existent token");
        require(ERC721.ownerOf(tokenId) == msg.sender, "Not your token");
        require(escrowedAt[tokenId] == 0, "Already in escrow");
        escrowedAt[tokenId] = block.timestamp;
    }

    function deEscrow(uint tokenId) public {
        require(escrowedAt[tokenId] != 0, "Not in escrow yet");
        require(ERC721._exists(tokenId), "Descrowing non existent token");
        require(ERC721.ownerOf(tokenId) == msg.sender, "Not your token");
        escrowPeriod[tokenId] += (block.timestamp - escrowedAt[tokenId]);
        escrowedAt[tokenId] = 0;
    }

    function getTokenPrice() public view returns (uint price) {
        return IBrokerDefiPriceConsumer(BROKER_DEFI_PRICE_CONSUMER).getPartnerPriceInEth();
    }

    function publicMint(address to, uint amount, uint code) public payable nonReentrant {
        require(amount > 0 && amount <= MAX_PER_TRX, "Invalid Amount");
        require(saleIsActive && treasury != address(0), "Config not done yet");
        require((TOKEN_ID + amount) <= MAX_SUPPLY, "Mint exceeds limits");
        uint nftPrice = getTokenPrice();
        require(msg.value >= (nftPrice * amount), "Not enough balance");
        if (code > 0) {
            require(partnerCodesVerification[code], "Wrong code");
            partnerCodesCount[code] += 1;
            uint commission = (msg.value / 100) * PARTNER_COMMISSION;
            uint discount = (msg.value / 100) * PARTNER_DISCOUNT;
            address payable recruiter = payable(ERC721.ownerOf(codeOwners[code]));
            recruiter.transfer(commission);
            treasury.transfer(msg.value - (commission + discount));
            address payable buyer = payable(msg.sender);
            buyer.transfer(discount); // transferring discount back to buyer
        } else {
            treasury.transfer(msg.value);
        }
        uint[] memory tokenIds = new uint[](amount);
        for (uint index = 0; index < amount; index++) {
            TOKEN_ID += 1;
            _safeMint(to, TOKEN_ID);
            tokenIds[index] = TOKEN_ID;
            setCode(TOKEN_ID);
        }
    }

    // mass minting function, one for each address, for team
    function massMint(address[] memory addresses) public onlyOwner() {
        for (uint index = 0; index < addresses.length; index++) {
            require(TEAM_COUNT < ALLOCATED_FOR_TEAM && (TOKEN_ID + 1) <= MAX_SUPPLY, "Amount exceeds allocation");
            TOKEN_ID += 1;
            _safeMint(addresses[index], TOKEN_ID);
            TEAM_COUNT += 1;
            setCode(TOKEN_ID);
        }
    }

    /**
        @dev Block transfers while escrowing.
     */

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        require(escrowedAt[tokenId] == 0, "BrokerDefi: transfer while escrow not allowed");
        ERC721.transferFrom(from, to, tokenId);
    }

    function safeTransferWhileEscrow(
        address from,
        address to,
        uint256 tokenId
    ) public {
        ERC721.safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(escrowedAt[tokenId] == 0, "BrokerDefi: transfer while escrow not allowed");
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(escrowedAt[tokenId] == 0, "BrokerDefi: transfer while escrow not allowed");
        require(ERC721._isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        ERC721._safeTransfer(from, to, tokenId, _data);
    }

    // additional burn function
    function burn(uint256 tokenId) public {
        require(ERC721._exists(tokenId), "Burning non existent token");
        require(ERC721.ownerOf(tokenId) == msg.sender, "Not your token");
        _burn(tokenId);
    }

    // token ids function for view only, convenience function for frontend to fulfil the gap of erc721 enumerable
    function ownerTokens() public view returns(uint[] memory) {
        uint[] memory tokenIds = new uint[](ERC721.balanceOf(msg.sender));
        uint tokenIdsIndex = 0;
        for (uint index = 1; index <= TOKEN_ID; index++) {
            if (ERC721.ownerOf(index) == msg.sender) {
                tokenIds[tokenIdsIndex] = index;
                tokenIdsIndex++;
            }
        }
        return tokenIds;
    }
}