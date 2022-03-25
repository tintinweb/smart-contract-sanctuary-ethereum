// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Nafflecampaign
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//    T                                                                                                                                                                 //
//    pragma solidity ^0.8.3;                                                                                                                                           //
//                                                                                                                                                                      //
//    interface ITicketNFT {                                                                                                                                            //
//        function customMint(address _owner, string memory _tokenURI, string memory _tokenMeta) external returns(uint256);                                             //
//    }                                                                                                                                                                 //
//                                                                                                                                                                      //
//    library SafeMath {                                                                                                                                                //
//        /**                                                                                                                                                           //
//         * @dev Returns the addition of two unsigned integers, with an overflow flag.                                                                                 //
//         *                                                                                                                                                            //
//         * _Available since v3.4._                                                                                                                                    //
//         */                                                                                                                                                           //
//        function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {                                                                                 //
//            unchecked {                                                                                                                                               //
//                uint256 c = a + b;                                                                                                                                    //
//                if (c < a) return (false, 0);                                                                                                                         //
//                return (true, c);                                                                                                                                     //
//            }                                                                                                                                                         //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /**                                                                                                                                                           //
//         * @dev Returns the substraction of two unsigned integers, with an overflow flag.                                                                             //
//         *                                                                                                                                                            //
//         * _Available since v3.4._                                                                                                                                    //
//         */                                                                                                                                                           //
//        function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {                                                                                 //
//            unchecked {                                                                                                                                               //
//                if (b > a) return (false, 0);                                                                                                                         //
//                return (true, a - b);                                                                                                                                 //
//            }                                                                                                                                                         //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /**                                                                                                                                                           //
//         * @dev Returns the multiplication of two unsigned integers, with an overflow flag.                                                                           //
//         *                                                                                                                                                            //
//         * _Available since v3.4._                                                                                                                                    //
//         */                                                                                                                                                           //
//        function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {                                                                                 //
//            unchecked {                                                                                                                                               //
//                // Gas optimization: this is cheaper than requiring 'a' not being zero, but the                                                                       //
//                // benefit is lost if 'b' is also tested.                                                                                                             //
//                // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522                                                                               //
//                if (a == 0) return (true, 0);                                                                                                                         //
//                uint256 c = a * b;                                                                                                                                    //
//                if (c / a != b) return (false, 0);                                                                                                                    //
//                return (true, c);                                                                                                                                     //
//            }                                                                                                                                                         //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /**                                                                                                                                                           //
//         * @dev Returns the division of two unsigned integers, with a division by zero flag.                                                                          //
//         *                                                                                                                                                            //
//         * _Available since v3.4._                                                                                                                                    //
//         */                                                                                                                                                           //
//        function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {                                                                                 //
//            unchecked {                                                                                                                                               //
//                if (b == 0) return (false, 0);                                                                                                                        //
//                return (true, a / b);                                                                                                                                 //
//            }                                                                                                                                                         //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /**                                                                                                                                                           //
//         * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.                                                                //
//         *                                                                                                                                                            //
//         * _Available since v3.4._                                                                                                                                    //
//         */                                                                                                                                                           //
//        function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {                                                                                 //
//            unchecked {                                                                                                                                               //
//                if (b == 0) return (false, 0);                                                                                                                        //
//                return (true, a % b);                                                                                                                                 //
//            }                                                                                                                                                         //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /**                                                                                                                                                           //
//         * @dev Returns the addition of two unsigned integers, reverting on                                                                                           //
//         * overflow.                                                                                                                                                  //
//         *                                                                                                                                                            //
//         * Counterpart to Solidity's `+` operator.                                                                                                                    //
//         *                                                                                                                                                            //
//         * Requirements:                                                                                                                                              //
//         *                                                                                                                                                            //
//         * - Addition cannot overflow.                                                                                                                                //
//         */                                                                                                                                                           //
//        function add(uint256 a, uint256 b) internal pure returns (uint256) {                                                                                          //
//            return a + b;                                                                                                                                             //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /**                                                                                                                                                           //
//         * @dev Returns the subtraction of two unsigned integers, reverting on                                                                                        //
//         * overflow (when the result is negative).                                                                                                                    //
//         *                                                                                                                                                            //
//         * Counterpart to Solidity's `-` operator.                                                                                                                    //
//         *                                                                                                                                                            //
//         * Requirements:                                                                                                                                              //
//         *                                                                                                                                                            //
//         * - Subtraction cannot overflow.                                                                                                                             //
//         */                                                                                                                                                           //
//        function sub(uint256 a, uint256 b) internal pure returns (uint256) {                                                                                          //
//            return a - b;                                                                                                                                             //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /**                                                                                                                                                           //
//         * @dev Returns the multiplication of two unsigned integers, reverting on                                                                                     //
//         * overflow.                                                                                                                                                  //
//         *                                                                                                                                                            //
//         * Counterpart to Solidity's `*` operator.                                                                                                                    //
//         *                                                                                                                                                            //
//         * Requirements:                                                                                                                                              //
//         *                                                                                                                                                            //
//         * - Multiplication cannot overflow.                                                                                                                          //
//         */                                                                                                                                                           //
//        function mul(uint256 a, uint256 b) internal pure returns (uint256) {                                                                                          //
//            return a * b;                                                                                                                                             //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /**                                                                                                                                                           //
//         * @dev Returns the integer division of two unsigned integers, reverting on                                                                                   //
//         * division by zero. The result is rounded towards zero.                                                                                                      //
//         *                                                                                                                                                            //
//         * Counterpart to Solidity's `/` operator.                                                                                                                    //
//         *                                                                                                                                                            //
//         * Requirements:                                                                                                                                              //
//         *                                                                                                                                                            //
//         * - The divisor cannot be zero.                                                                                                                              //
//         */                                                                                                                                                           //
//        function div(uint256 a, uint256 b) internal pure returns (uint256) {                                                                                          //
//            return a / b;                                                                                                                                             //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /**                                                                                                                                                           //
//         * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),                                                                   //
//         * reverting when dividing by zero.                                                                                                                           //
//         *                                                                                                                                                            //
//         * Counterpart to Solidity's `%` operator. This function uses a `revert`                                                                                      //
//         * opcode (which leaves remaining gas untouched) while Solidity uses an                                                                                       //
//         * invalid opcode to revert (consuming all remaining gas).                                                                                                    //
//         *                                                                                                                                                            //
//         * Requirements:                                                                                                                                              //
//         *                                                                                                                                                            //
//         * - The divisor cannot be zero.                                                                                                                              //
//         */                                                                                                                                                           //
//        function mod(uint256 a, uint256 b) internal pure returns (uint256) {                                                                                          //
//            return a % b;                                                                                                                                             //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /**                                                                                                                                                           //
//         * @dev Returns the subtraction of two unsigned integers, reverting with custom message on                                                                    //
//         * overflow (when the result is negative).                                                                                                                    //
//         *                                                                                                                                                            //
//         * CAUTION: This function is deprecated because it requires allocating memory for the error                                                                   //
//         * message unnecessarily. For custom revert reasons use {trySub}.                                                                                             //
//         *                                                                                                                                                            //
//         * Counterpart to Solidity's `-` operator.                                                                                                                    //
//         *                                                                                                                                                            //
//         * Requirements:                                                                                                                                              //
//         *                                                                                                                                                            //
//         * - Subtraction cannot overflow.                                                                                                                             //
//         */                                                                                                                                                           //
//        function sub(                                                                                                                                                 //
//            uint256 a,                                                                                                                                                //
//            uint256 b,                                                                                                                                                //
//            string memory errorMessage                                                                                                                                //
//        ) internal pure returns (uint256) {                                                                                                                           //
//            unchecked {                                                                                                                                               //
//                require(b <= a, errorMessage);                                                                                                                        //
//                return a - b;                                                                                                                                         //
//            }                                                                                                                                                         //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /**                                                                                                                                                           //
//         * @dev Returns the integer division of two unsigned integers, reverting with custom message on                                                               //
//         * division by zero. The result is rounded towards zero.                                                                                                      //
//         *                                                                                                                                                            //
//         * Counterpart to Solidity's `/` operator. Note: this function uses a                                                                                         //
//         * `revert` opcode (which leaves remaining gas untouched) while Solidity                                                                                      //
//         * uses an invalid opcode to revert (consuming all remaining gas).                                                                                            //
//         *                                                                                                                                                            //
//         * Requirements:                                                                                                                                              //
//         *                                                                                                                                                            //
//         * - The divisor cannot be zero.                                                                                                                              //
//         */                                                                                                                                                           //
//        function div(                                                                                                                                                 //
//            uint256 a,                                                                                                                                                //
//            uint256 b,                                                                                                                                                //
//            string memory errorMessage                                                                                                                                //
//        ) internal pure returns (uint256) {                                                                                                                           //
//            unchecked {                                                                                                                                               //
//                require(b > 0, errorMessage);                                                                                                                         //
//                return a / b;                                                                                                                                         //
//            }                                                                                                                                                         //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /**                                                                                                                                                           //
//         * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),                                                                   //
//         * reverting with custom message when dividing by zero.                                                                                                       //
//         *                                                                                                                                                            //
//         * CAUTION: This function is deprecated because it requires allocating memory for the error                                                                   //
//         * message unnecessarily. For custom revert reasons use {tryMod}.                                                                                             //
//         *                                                                                                                                                            //
//         * Counterpart to Solidity's `%` operator. This function uses a `revert`                                                                                      //
//         * opcode (which leaves remaining gas untouched) while Solidity uses an                                                                                       //
//         * invalid opcode to revert (consuming all remaining gas).                                                                                                    //
//         *                                                                                                                                                            //
//         * Requirements:                                                                                                                                              //
//         *                                                                                                                                                            //
//         * - The divisor cannot be zero.                                                                                                                              //
//         */                                                                                                                                                           //
//        function mod(                                                                                                                                                 //
//            uint256 a,                                                                                                                                                //
//            uint256 b,                                                                                                                                                //
//            string memory errorMessage                                                                                                                                //
//        ) internal pure returns (uint256) {                                                                                                                           //
//            unchecked {                                                                                                                                               //
//                require(b > 0, errorMessage);                                                                                                                         //
//                return a % b;                                                                                                                                         //
//            }                                                                                                                                                         //
//        }                                                                                                                                                             //
//    }                                                                                                                                                                 //
//                                                                                                                                                                      //
//    interface IERC165 {                                                                                                                                               //
//        function supportsInterface(bytes4 interfaceId) external view returns (bool);                                                                                  //
//    }                                                                                                                                                                 //
//                                                                                                                                                                      //
//    interface IERC721 is IERC165 {                                                                                                                                    //
//        event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);                                                                            //
//                                                                                                                                                                      //
//        event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);                                                                     //
//                                                                                                                                                                      //
//        event ApprovalForAll(address indexed owner, address indexed operator, bool approved);                                                                         //
//                                                                                                                                                                      //
//        function balanceOf(address owner) external view returns (uint256 balance);                                                                                    //
//                                                                                                                                                                      //
//        function ownerOf(uint256 tokenId) external view returns (address owner);                                                                                      //
//                                                                                                                                                                      //
//        function safeTransferFrom(                                                                                                                                    //
//            address from,                                                                                                                                             //
//            address to,                                                                                                                                               //
//            uint256 tokenId                                                                                                                                           //
//        ) external;                                                                                                                                                   //
//                                                                                                                                                                      //
//        function transferFrom(                                                                                                                                        //
//            address from,                                                                                                                                             //
//            address to,                                                                                                                                               //
//            uint256 tokenId                                                                                                                                           //
//        ) external;                                                                                                                                                   //
//                                                                                                                                                                      //
//        function approve(address to, uint256 tokenId) external;                                                                                                       //
//                                                                                                                                                                      //
//        function getApproved(uint256 tokenId) external view returns (address operator);                                                                               //
//                                                                                                                                                                      //
//        function setApprovalForAll(address operator, bool _approved) external;                                                                                        //
//                                                                                                                                                                      //
//        function isApprovedForAll(address owner, address operator) external view returns (bool);                                                                      //
//                                                                                                                                                                      //
//        function safeTransferFrom(                                                                                                                                    //
//            address from,                                                                                                                                             //
//            address to,                                                                                                                                               //
//            uint256 tokenId,                                                                                                                                          //
//            bytes calldata data                                                                                                                                       //
//        ) external;                                                                                                                                                   //
//    }                                                                                                                                                                 //
//                                                                                                                                                                      //
//    interface IERC721Receiver {                                                                                                                                       //
//        /**                                                                                                                                                           //
//         * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}                                                  //
//         * by `operator` from `from`, this function is called.                                                                                                        //
//         *                                                                                                                                                            //
//         * It must return its Solidity selector to confirm the token transfer.                                                                                        //
//         * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.                                        //
//         *                                                                                                                                                            //
//         * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.                                                                         //
//         */                                                                                                                                                           //
//        function onERC721Received(                                                                                                                                    //
//            address operator,                                                                                                                                         //
//            address from,                                                                                                                                             //
//            uint256 tokenId,                                                                                                                                          //
//            bytes calldata data                                                                                                                                       //
//        ) external returns (bytes4);                                                                                                                                  //
//    }                                                                                                                                                                 //
//                                                                                                                                                                      //
//    struct Campaign {                                                                                                                                                 //
//        uint256 campaignId;                                                                                                                                           //
//        uint256 totalTickets;                                                                                                                                         //
//        uint256 ticketPrice;                                                                                                                                          //
//        uint256 startTime;                                                                                                                                            //
//        uint256 endTime;                                                                                                                                              //
//        uint256[] tickets;                                                                                                                                            //
//                                                                                                                                                                      //
//        address creator;                                                                                                                                              //
//        address winner;                                                                                                                                               //
//                                                                                                                                                                      //
//        address nftAddress;                                                                                                                                           //
//        uint256 nftTokenId;                                                                                                                                           //
//                                                                                                                                                                      //
//        IERC721 nftItem;                                                                                                                                              //
//                                                                                                                                                                      //
//        uint256 price;                                                                                                                                                //
//        mapping (uint256 => address) ticketIdToBuyer;                                                                                                                 //
//        uint256 currentTicketCountForCache;                                                                                                                           //
//    }                                                                                                                                                                 //
//                                                                                                                                                                      //
//    struct NFTInfo {                                                                                                                                                  //
//        uint256 campaignId;                                                                                                                                           //
//        address nftAddress;                                                                                                                                           //
//        uint256 nftTokenId;                                                                                                                                           //
//        uint256 price;                                                                                                                                                //
//        uint256 ticketPrice;                                                                                                                                          //
//    }                                                                                                                                                                 //
//                                                                                                                                                                      //
//    contract Raffle {                                                                                                                                                 //
//        using SafeMath for uint256;                                                                                                                                   //
//        ITicketNFT ticketNFT;                                                                                                                                         //
//                                                                                                                                                                      //
//        mapping (address => uint256[]) public ownerToTickets;                                                                                                         //
//        mapping (address => address) public nftAddressToOwner;                                                                                                        //
//        mapping (address => address) public ownerAddressToNft;                                                                                                        //
//        mapping (address => address[]) public ownerToNftAddresses;                                                                                                    //
//        mapping (address => mapping (uint256 => Campaign)) public creatorToCampaign;                                                                                  //
//        // mapping (address => Campaign[]) public creatorToCampaign;                                                                                                  //
//        mapping (uint256 => uint256) public ticketIdToBuyTime;                                                                                                        //
//        mapping (address => uint256) public buyerToTicketId;                                                                                                          //
//                                                                                                                                                                      //
//        mapping (address => uint256) public creatorToCampaignSize;                                                                                                    //
//        mapping (address => mapping (uint256 => Campaign)) public campaignCache;                                                                                      //
//                                                                                                                                                                      //
//        uint256 private maxBuyAmount = 9000;                                                                                                                          //
//        uint256 private maxTicketNumber = 10000;                                                                                                                      //
//        uint256 private minTicketNumber = 2;                                                                                                                          //
//                                                                                                                                                                      //
//        uint256 public _balance = address(this).balance;                                                                                                              //
//        uint256 public platformFee = 5;                                                                                                                               //
//        uint256 public penaltyFee = 10;                                                                                                                               //
//        uint256 public maxTicketAmount = 100;                                                                                                                         //
//                                                                                                                                                                      //
//        bool private isWhiteListMode = false;                                                                                                                         //
//        mapping (address => bool) private whiteList;                                                                                                                  //
//        mapping (address => mapping (uint256 => bool)) private nftAddressToTokenId;                                                                                   //
//        address private admin;                                                                                                                                        //
//                                                                                                                                                                      //
//        NFTInfo[] NFTInfos;                                                                                                                                           //
//                                                                                                                                                                      //
//        constructor (address _ticketAddress) {                                                                                                                        //
//            admin = msg.sender;                                                                                                                                       //
//            ticketNFT = ITicketNFT(_ticketAddress);                                                                                                                   //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /*_______________________________________Modifiers______________________________________*/                                                                    //
//                                                                                                                                                                      //
//        modifier onlyAdmin {                                                                                                                                          //
//            require(msg.sender == admin, "Access denied. Only admin.");                                                                                               //
//            _;                                                                                                                                                        //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        modifier whitelistManager(address _address) {                                                                                                                 //
//            require(isWhiteListMode == false || whiteList[_address] == true, "You are not in whitelist.");                                                            //
//            _;                                                                                                                                                        //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        modifier checkingExistCampaign(address _creator, uint256 _campaignIndex) {                                                                                    //
//            require(creatorToCampaign[_creator][_campaignIndex].creator != address(0), "Can't find the campaign.");                                                   //
//            _;                                                                                                                                                        //
//        }                                                                                                                                                             //
//                                                                                                                                                                      //
//        /*_______________________________________Campaign Operation______________________________________*/                                                           //
//                                                                                                                                                                      //
//        function createCampaign (address _nftAddress, uint256 _nftTokenId, uint256 _totalTickets, uint256 _price, uint256 _ticketPrice, uint256 _endTime) public {    //
//            require(block.timestamp < _endTime, "Incorrect campaign time.");                                                                                          //
//            require(_totalTickets >= minTicketNumber && _totalTickets <= maxTicketNumber, "Incorrect number of ticket.");                                             //
//            require(nftAddressToTokenId[_nftAddress][_nftTokenId] == false, "This NFT is already ordered.");                                                          //
//                                                                                                                                                                      //
//            address _creator = msg.sender;                                                                                                                            //
//            uint256 _campaignIndex = getLastCampaignIndex(_creator);                                                                                                  //
//                                                                                                                                                                      //
//            nftAddressToTokenId[_nftAddress][_nftTokenId] = true;                                                                                                     //
//                                                                                                                                                                      //
//            creatorToCampaign[_creator][_campaignIndex].campaignId = _campaignIndex;                                                                                  //
//            creatorToCampaign[_creator][_campaignIndex].totalTickets = _totalTickets;                                                                                 //
//            creatorToCampaign[_creator][_campaignIndex].price = _price;                                                                                               //
//            creatorToCampaign[_creator][_campaignIndex].ticketPrice = _ticketPrice;                                                                                   //
//            creatorToCampaign[_creator][_campaignIndex].startTime = block.timestamp;                                                                                  //
//            creatorToCampaign[_creator][_campaignIndex].endTime = _endTime;                                                                                           //
//            creatorToCampaign[_creator][_campaignIndex].creator = _creator;                                                                                           //
//            creatorToCampaign[_creator][_campaignIndex].nftAddress = _nftAddress;                                                                                     //
//            creatorToCampaign[_creator][_campaignIndex].nftTokenId = _nftTokenId;                                                                                     //
//                                                                                                                                                                      //
//            creatorToCampaign[_creator][_campaignIndex].nftItem = IERC721(_nftAddress);                                                                               //
//                                                                                                                                                                      //
//            creatorToCampaignSize[_creator] = creatorToCampaignSize[_creator].add(1);                                                                                 //
//                                                                                                                                                                      //
//            addNftToList(_ca                                                                                                                                          //
//                                                                                                                                                                      //
//                                                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract Nafflecampaign is ERC721Creator {
    constructor() ERC721Creator("Nafflecampaign", "Nafflecampaign") {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

contract ERC721Creator is Proxy {
    
    constructor(string memory name, string memory symbol) {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = 0x80d39537860Dc3677E9345706697bf4dF6527f72;
        Address.functionDelegateCall(
            0x80d39537860Dc3677E9345706697bf4dF6527f72,
            abi.encodeWithSignature("initialize(string,string)", name, symbol)
        );
    }
        
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
     function implementation() public view returns (address) {
        return _implementation();
    }

    function _implementation() internal override view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}