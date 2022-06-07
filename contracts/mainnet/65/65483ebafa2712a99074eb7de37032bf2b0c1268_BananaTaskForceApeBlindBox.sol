/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.7;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    int256 constant private INT256_MIN = -2**255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == INT256_MIN)); // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0); // Solidity only automatically asserts when dividing by 0
        require(!(b == -1 && a == INT256_MIN)); // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
interface IERC721Metadata {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

interface IERC721Mintable is IERC721, IERC721Enumerable, IERC721Metadata {
    function autoMint(string memory tokenURI, address to) external returns (uint256);
    function mintWithTokenURI(address to, uint256 tokenId, string memory tokenURI) external returns (bool);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

contract BananaTaskForceApeBlindBox {
    using SafeMath for uint256;

    address public owner;
    address public nftContractAddress;
    address payable public wallet;

    bool public enabled;
    uint256 public reserved;
    uint256 public reserveLimit;
    bool public onlyWhitelist;
    uint256 public whitelistLimit;
    uint256 public buyLimit;

    IERC721Mintable private NFT_MINTABLE;

    uint256 public totalCreated;
    mapping(uint256 => uint256) private boxIndexes;
    mapping(address => uint256[]) private ownerBoxes;
    mapping(address => bool) public whitelist;

    Blindbox[] private soldBoxes;

    uint private nonce = 0;

    uint256 cost;
    uint256 total;
    uint256 remaining;
    mapping (uint256 => bool) issued;

    struct Blindbox {
        uint256 id;
        address purchaser;
        uint256 tokenID;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "can only be called by the contract owner");
        _;
    }

    modifier isEnabled() {
        require(enabled, "Contract is currently disabled");
        _;
    }

    constructor() {
        owner = msg.sender;
        wallet = payable(0x1764041440eD4081Ae361EC9c2245Eb33F023F60);
        onlyWhitelist = true;
        whitelistLimit = 10;
        buyLimit = 5;
        reserveLimit = 500;

        // Nft Contract
        nftContractAddress = 0x510EBF6EaDd8acaE95c790212624ccA7CEcBBa73;
        NFT_MINTABLE = IERC721Mintable(nftContractAddress);

        cost = 99 * 10 ** 15;
        total = 10000;
        remaining = 10000;
    }

    function status() public view returns (bool canPurchase, uint256 boxCost, uint256 boxRemaining, uint256 hasPurchased, uint256 purchaseLimit) {
        canPurchase = enabled && ((onlyWhitelist == false && ownerBoxes[msg.sender].length < buyLimit) || (whitelist[msg.sender] && ownerBoxes[msg.sender].length < whitelistLimit));
        boxCost = cost;
        boxRemaining = remaining;
        hasPurchased = ownerBoxes[msg.sender].length;
        purchaseLimit = whitelistLimit;
    }

    function purchaseBlindbox() public payable isEnabled {
        require (remaining > 0, "No more blindboxes available");
        require((onlyWhitelist == false && ownerBoxes[msg.sender].length < buyLimit) || (whitelist[msg.sender] && ownerBoxes[msg.sender].length < whitelistLimit), "You are not on the whitelist");
        require (msg.value == cost, "Incorrect BNB value.");

        wallet.transfer(cost);

        mint(msg.sender);
    }

    function balanceOf(address who) public view returns (Blindbox[] memory) {
        Blindbox[] memory boxes = new Blindbox[](ownerBoxes[who].length);

        for (uint256 i = 0; i < ownerBoxes[who].length; i++) {
            boxes[i] = soldBoxes[ownerBoxes[who][i]];
        }

        return boxes;
    }


    // Private methods

   function mint(address who) private {
        uint256 request = requestRandomWords();
        soldBoxes.push(Blindbox(
            request,
            who,
            0
        ));

        uint256 index = soldBoxes.length - 1;
        boxIndexes[request] = index;
        ownerBoxes[who].push(index);

        uint256 roll = soldBoxes[boxIndexes[index]].id.mod(remaining).add(1);
        uint256 current;
        uint256 tokenId;
        string memory uri;
        for (uint256 i = 1; i <= total; i++) {
            if (issued[i] == false) {
                current += 1;
            }
            if (roll <= current) {
                uri = string(abi.encodePacked("https://nftstorage.link/ipfs/bafybeic2hzyfaxo7gvezfnllsgxusjpb6rj6s77vru34yhbnghdjkxv3xe/", uint2str(i), ".json"));
                issued[i] = true;
                tokenId = i;
                break;
            }
        }
        remaining--;

        require(NFT_MINTABLE.mintWithTokenURI(who, tokenId, uri), "Minting error");
        soldBoxes[boxIndexes[index]].tokenID = tokenId;
    }


    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function requestRandomWords() private returns (uint256) {
        nonce += 1;
        return uint(keccak256(abi.encodePacked(nonce, msg.sender, blockhash(block.number - 1))));
    }


    // Admin Only

    function setOwner(address who) external onlyOwner {
        require(who != address(0), "Cannot be zero address");
        owner = who;
    }

    function setWallet(address payable who) external onlyOwner {
        require(who != address(0), "Cannot be zero address");
        wallet = who;
    }

    function setPrice(uint256 price) external onlyOwner {
        cost = price;
    }

    function setEnabled(bool canPurchase) external onlyOwner {
        enabled = canPurchase;
    }

    function enableWhitelist(bool on) external onlyOwner {
        onlyWhitelist = on;
    }

    function setWhitelist(address who, bool whitelisted) external onlyOwner {
        whitelist[who] = whitelisted;
    }

    function setWhitelisted(address[] memory who, bool whitelisted) external onlyOwner {
        for (uint256 i = 0; i < who.length; i++) {
            whitelist[who[i]] = whitelisted;
        }
    }

    function setBuyLimits(uint256 white, uint256 normal) external onlyOwner {
        whitelistLimit = white;
        buyLimit = normal;
    }

    function reserveNfts(address who, uint256 amount) external onlyOwner {
        require(reserved + amount <= reserveLimit, "NFTS have already been reserved");

        for (uint256 i = 0; i < amount; i++) {
            mint(who);
        }

        reserved += amount;
    }
}