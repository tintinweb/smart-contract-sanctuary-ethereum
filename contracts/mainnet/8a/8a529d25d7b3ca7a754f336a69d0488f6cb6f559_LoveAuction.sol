/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

//       :                                   .                                 
                        //      ^PY7                               :!!                                 
                        //      ~GB5?.                            !??:                                 
                        //      ~&&G?J.                          !PJY5:                                
                        //      ~&B#G#Y.                        !PJYB#.                                
                        //      !#B&#5P5.                     .7GBG&@&:                                
                        //      ~##&#PG#Y                    [email protected]@@#:                                
                        //      :B#55BP5B5:                  ^[email protected]@&B.                                
                        //      .GG?Y&BPJ?J.                ~7^7G#B#BB.                                
                        //      :GG5BGBB5~?J.              !J!^JBG5PG5                                 
                        //      :B&BBBGB#BP5?             !G?!!JY555Y~                                 
                        //      :B#B&&G#BB#!!!           :GG?BP5G&B555.                                
                        //      .B#B&&#&B&&GJB!         .5#GGBG###GPGP                                 
                        //      .GG#&&&@&#BGYBG:        7P#P&#GB#5BGB?                                 
                        //      :P##GBGBGGB5??#J       :7Y##5BB#5P#B5Y                                 
                        //      .5GP5PPPPG#G55?P^      ?5#@BPBB5YPB5JJ                                 
                        //       ?P555BB#&@#P#^77.    ^JG#GY5Y5PYYYY?:                                 
                        //       ^#GPGP#&G&&#@Y!J?   .YG5JPJPB#&55PBJ.                                 
                        //        7##[email protected]&G#&~YB:  7#PY?#B#&###@##^                                  
                        //         !###&PP&#5B#5Y&? .5YP5P&B#&#&@GP~                                   
                        //          ^[email protected]#G#@#B#JB?&B:?GGPG&PBB&&#PJ:                                    
                        //           .Y&BBP5#[email protected]#5#5YB&?5#JBBGYY?.                                     
                        //             5GY77&Y?J?BY^:P#!P5PY57^J.                                      
                        //             ^5~^~5J~.!BJ?7YY~~~BJ?5?~                                       
                        //            ~!!J!~~777YP5YJ?5YJ?#J?JJ?!^.                                    
                        //         .!5?:!YJ?777J75?..:~!7?GPGJPBGP5!                                   
                        //        ^?YJ^~JYGJB5JBGBY.^~YJYJJ#5GGPPBGJ!:.                                
                        //      ^??~^~7JY?PJ&5BB#GPP&YGP#P7BGBYBPY??J?7^                               
                        //     [email protected]##&#&@BY&B&5?B?!G#?!!7JYYJ^                              
                        //    .55JJ???JJJ#P&#&!5B#&#YG&&#GGG?!?G7^!7?YJY?                              
                        //    .PP5YYYYY5~Y#BBG 7P#P?Y&#BB~Y!..?G~.!?J??YJ                              
                        //    ^GGP5P55PPY!BG&P?~JJ7!5G55G~7..:GP..?J???Y5.                             
                        //    ^B#G555PGGBJ?B#B&J?77JJ:YYGYY~~YG! 7YJ?JPPP:                             
                        //    :P###PP55PGB?G#&GYJ?JBJ7P5YGG..PB^7YY5PBBB5.                             
                        //     7##PG&B#PPG5P&&G55#&@G5&[email protected]~?G#J55B&&##B7                              
                        //      Y#P#GP&&&&#&@#BB&[email protected]@[email protected]&&B##&&&#G7                               
                        //       7B&GPGB#PP&@&#@#[email protected]&&B&#JY##&&G##B5Y7                                
                        //        ^JG5JP#5G#GB#&BGP&@@&&@[email protected]?5JJ!:                                 
                        //          :7?JJY##GPG&G5#&G&#&#BGGY7GJ7!~:                                   
                        //            .:!?Y5PGP55G5?5&G#J7?7777~:.                                     
                        //                :~7YGGP5PB5YJGY5Y!~:.                                        
                        //                    :^!JYY5J777^.                                            
                        //                         ...        

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/a.sol



pragma solidity >=0.7.0 <0.9.0;




interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract LoveAuction is Ownable, ERC721Holder {

    mapping(address => uint256) public biderBurns;
    address[] public biders;

    bool public isOpen = false;
    uint256 public totalBurned = 0;

    IERC721 loveLoves;

    address targetAddress = 0x000000000000000000000000000000000000dEaD;

    constructor(address nftAddress) {
        loveLoves = IERC721(nftAddress);
    }

    function bid(uint256[] calldata ids) public {
        require(isOpen, "not start");
        require(ids.length > 0, "need love");

        if(biderBurns[msg.sender] == 0) {
          biders.push(msg.sender);
        }

        biderBurns[msg.sender] += ids.length;
        totalBurned += ids.length;

        for (uint i=0; i< ids.length; i++) {
            loveLoves.transferFrom(
                msg.sender, targetAddress, ids[i]
            );
        }
    }

    function toggleOpen() public onlyOwner {
        isOpen = !isOpen;
    }

    function setTarget(address newTarget) public onlyOwner {
        targetAddress = newTarget;
    }

    function totalBider() public view returns (uint256) {
        return biders.length;
    }

    function getBurnInfo(uint index) public view returns(address bider, uint burns) {
        bider = biders[index];
        burns = biderBurns[bider];
    }

    struct BurnInfo {
      address bider;
      uint burns;
    }

    function page(uint256 pageIndex, uint256 pageSize) public view returns (BurnInfo[] memory burners) {
        uint256 start = pageIndex * pageSize;
        uint256 length = _min(pageSize, start > biders.length ? 0: biders.length - start);
        burners = new BurnInfo[](length);
        for (uint i = 0; i < length ; i++) {
            (address bider, uint burns) = getBurnInfo(start + i);
            burners[i] = BurnInfo(bider, burns);
        }
    }

    function _min(uint a, uint b) internal pure returns (uint) {
      return a >= b ? b : a;
    }
}