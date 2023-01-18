// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "./IERC165.sol";

/// @title ERC-1155 Multi Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// Note: The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 is IERC165 {
    /// @dev
    /// - Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
    /// - The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
    /// - The `_from` argument MUST be the address of the holder whose balance is decreased.
    /// - The `_to` argument MUST be the address of the recipient whose balance is increased.
    /// - The `_id` argument MUST be the token type being transferred.
    /// - The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
    /// - When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
    /// - When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    event TransferSingle(
        address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value
    );

    /// @dev
    /// - Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
    /// - The `_operator` argument MUST be the address of an account/contract that is approved to make the transfer (SHOULD be msg.sender).
    /// - The `_from` argument MUST be the address of the holder whose balance is decreased.
    /// - The `_to` argument MUST be the address of the recipient whose balance is increased.
    /// - The `_ids` argument MUST be the list of tokens being transferred.
    /// - The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
    /// - When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
    /// - When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    event TransferBatch(
        address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values
    );

    /// @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absence of an event assumes disabled).
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @dev MUST emit when the URI is updated for a token ID. URIs are defined in RFC 3986.
    /// The URI MUST point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    event URI(string _value, uint256 indexed _id);

    /// @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// - MUST revert if `_to` is the zero address.
    /// - MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
    /// - MUST revert on any other error.
    /// - MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
    /// - After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from Source address
    /// @param _to Target address
    /// @param _id ID of the token type
    /// @param _value Transfer amount
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /// @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
    /// @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
    /// - MUST revert if `_to` is the zero address.
    /// - MUST revert if length of `_ids` is not the same as length of `_values`.
    /// - MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
    /// - MUST revert on any other error.
    /// - MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
    /// - Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
    /// - After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
    /// @param _from Source address
    /// @param _to Target address
    /// @param _ids IDs of each token type (order and length must match _values array)
    /// @param _values Transfer amounts per token type (order and length must match _ids array)
    /// @param _data Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    /// @notice Get the balance of an account's tokens.
    /// @param _owner The address of the token holder
    /// @param _id ID of the token
    /// @return The _owner's balance of the token type requested
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /// @notice Get the balance of multiple account/token pairs
    /// @param _owners The addresses of the token holders
    /// @param _ids ID of the tokens
    /// @return The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    /// @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
    /// @dev MUST emit the ApprovalForAll event on success.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Queries the approval status of an operator for a given owner.
    /// @param _owner The owner of the tokens
    /// @param _operator Address of authorized operator
    /// @return True if the operator is approved, false if not
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    /// uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    /// `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

struct NCAParams {
    string seed;
    string bg;
    string fg1;
    string fg2;
    string matrix;
    string activation;
    string rand;
    string mods;
}

interface INeuralAutomataEngine {
    function baseScript() external view returns(string memory);

    function parameters(NCAParams memory _params) external pure returns(string memory);

    function p5() external view returns(string memory);

    function script(NCAParams memory _params) external view returns(string memory);

    function page(NCAParams memory _params) external view returns(string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IOschuns {
    event FailedRefund(address _to, uint256 _value);
    
    function endTime() external view returns(uint256);

    function bidder(address) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {NCAParams} from "./INeuralAutomataEngine.sol";

interface IZooOfNeuralAutomata {

    function updateEngine(address _engine) external;

    function updateContractURI(string memory _contractURI) external;

    function updateParams(uint256 _id, NCAParams memory _params) external;

    function updateMinter(uint256 _id, address _minter) external;

    function updateBurner(uint256 _id, address _burner) external;

    function updateBaseURI(uint256 _id, string memory _baseURI) external;

    function freeze(uint256 _id) external;

    function newToken(
        uint256 _id,
        NCAParams memory _params, 
        address _minter, 
        address _burner,
        string memory _baseURI
    ) external;

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external;

    function burn(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external;
    
}

/* SPDX-License-Identifier: MIT
                                 :~!7!777!!~:.     .::::::.                                         
                               :!7?7?!77~?~777!. :~!~^~~!!~~^:.   .                                 
                              ~?!~77!!^!!7!!!?JY?Y?~^~~~!7!77!!^^^:                                 
                             ^J!!!~.     :!!!7?PPYJ!~^:.  ...:^^..                                  
                         :!7 ^Y!7^        :~77YPGP5Y7~~^:.:.                                        
                .::::::::7JY~!?^!:       :~!7Y5PBBGPPP5YJ??7!~^:.                                   
            .^~7?77?777???JJYYY7^      .^!?JJY5Y!JPPPGPPPP555J?77~:          .::^^::..              
          .~7777~7?!J~?~~7!7JJ5?^     ^~7JJJJ5Y.   .^!?YPGPP55YJYJ?!.    .~7??777777!!~^:           
         ^7???~77^!:~^7^7J~7!7YYY?^ ^!7????JY5^         :~JPGYJ5J???7~ ^7JJJ77!!~~!!!!!!!!:         
        ^J??7!~.       .^!77!~7JYPP7?JJJJJ?YP~             ~PJ?JY?7??!?YJYJ!~~~^^^::^^!!777^        
       .JJ?7!.           .!!77!JYY5GYJJJ7??JY:              55?JJ?7??J5YY5Y7~:.        .77!7        
       :YJ7!.             ~!7??YJJ5P5J??77?Y5J:           :?Y7JJ7!!!JPPJJYY7~^     :.   ~7!!        
       ^YJ7~             :^7??JYJJYBBJ!7?JY5PPPJJYYJJ??77JPPJJJ?!~~7P&G5YY5J!~.    ^777!!7!.        
        ?Y?^            :!7?YYY555PYJB5JYPGG555YYJYJJJY55PPPPPY???JPBYGPP555J!~.    .^~~^:          
        ^Y7~           :!7?YY55YPP?  J#GPG55YJJJJ???????JY5PPGP5J5GJ: !GGP555J7~.                   
     .~~!J5J^^:       .~!JJYY55PBY    YBP5JYJJJ?7?J???7??JYYYPGGP5~    7GPPPP5?!~:                  
      .:?J?77??J7:    :!?5YYJYPPB?   ~BB5YJ?JJJJYY?????J???JY5PBY       7PPPP5Y7!!:     ^~~~~^^:.   
       ~!77^^^!755~   :7JYYJ?JJYP5   ?#GPYYYYYYYJJJ?J7?J??JJY5GB5        YPPP5P5J7~: .7YY7!!~!!7~^. 
       ~~7.   :!YPP.  :7?JYYJ?JY5GJ. !BBGP55YYYYJYJJJJJJ?JJY5PBBP.       ^PP5PP5YJ?77GG57~^....!??~.
       .^!.   ~?Y5P.   ~??JJJJJJYYGPJJBBBGPP55YYJYYJYJJJJJYY5GBBJ         5PG55YJJ??75PY?~^     ^J~:
         . .^7JY5P?    .~???JJYYJYY5P#&BBBGGPP55555YYY5YY5PGGBBP.        ^P5YY5P5J?JJP5JJ7!:     ^!:
        .^~7JYY5P7       ^?GP5P555PPPPB#BBGGPPPPPPPPPPPPGGGGGGBP.       ^55JJ5JJYJJJ5#BPJJ?!^.    ..
     .:~7?YY5PPY^      .!J5555PPGPP5P55G##BGGPGGGGGGGGGGGGGGPGGGY^:...~7GYYJ5YJ??JJYBGBG5PY?!^.     
    :~7JYY555J~       ~YJJ?????JJYPGP555BBBBBGGGGGGGGGGGGGGGPPBP55YYYYPYY555Y??J??Y5! ~PGG55?!~^.   
  .^7JY5P55J^        ^5?77~^~!77JYYPBPGP#GYPBGGBGBBGPPPPP5PPPY5#GP5Y5Y555JYJJ7??JYY~   ^PGP5YY!~^.  
 .!7Y55J5PJ.         !5?!.   .!77JJYPBBB&GPGGGBBGBGP555PPGGPBP5BBP5555YYYYJ???JYY7:     7GPP5Y?!~~: 
.!!?5555YP:        . ^JJ:     !!!!JYG#BBGBGGY^:7GBGPY5PPBY:.!BGGGPPPPYY?YYYJJ5Y7:       :G5PYYJ!~~^ 
:!!JYY5555:       .~!!!~    .~!!~!?5B#G5PGGG57!?GBGPPPPGBP??YGP55P5PP55Y5PP55?:        .JG5P5YJ?!~^ 
^~~JJYY5J5J:              .:~~~^~7JP#PPPBPPGGBBBGGGPPPPPPGPP5Y5555555555PGGGG5?7!~^~~7YGGJYP5YJ?!!: 
:7~J5PY?7J55?~:..    .:^^^~~^!~~!?PBPY55GGGGGBBGGGBGGGGPPP55YJYPPP5YJJJYYYY5P5PP555555P5JJ5YY?7!~~. 
 ^!!?55YJJYYYYJJ???YYPJ!~~~!~~!!?PBG5Y55PGPPGGGPPPGBBGGGGPYYY5YYPPPYYJJ???J?J?J7?77?7J??7JYYJ!~~~.  
 .~7!?Y55YYYJYYJJJPPJ!~^~!~~!~!JGBPP55PPP5Y5PPP55PPPPGGG55YYYY5Y5P5Y?7J7?!J777!!!?JJJJJJJYYJ!~!^.   
   :^!7?YY55YYYYPP57~^!!~!^~?J5P5YY55PGG555PP5Y?JYPGGGGGPPY5Y?YPPP5YYYYYJ?JJ?JYYY5P555P5PPPP!:.     
     .^~!77?Y5GBB5~:!~~!^~7JPG5YY555GGGP5JYYYJJYYY5PPPGGGP5YY?JPGGGPPPYYYYY5PGGP5PY??JJ???J57       
        .~~~??YGY^!~^~^!7JPBGPPPGPPB##PY?JJJJJYYJY5PPPPPP5YJJ?JYYBGY~:::...^GP5YJY?!~^:^^~!7?~      
            :^~7?77~^!!7Y5PYJ?!~^:.7#GYJ???JJ?JJY5P5PPPP55JJ777?YPB!       ?P5555J!^.::. !?777      
               :~^:!!~7YPP!       :PB5YJJJJJJJYYYY?~!5G55YYYJ77?J5#7      ^P55YJ?!~.7??::YJ??!      
               ~7^7!!7Y55PG5!^:.^JBB5YPJJJ5YYYYY?^   ^Y55YY7??JJJYGG:    .YP555J!~:.J7!7JJJ?!.      
               :~^!7!?JY5YYPGPPPGGPYPP5YYJJJYJ?!.    .!J55J7Y?J7JJ5GGJ~^!JGP55Y7~^. .~!!!!~:        
                ~~~!!7JJYJYYYYJ5JJ?J5G55JJ?J?7^.       ~?YYJJ77777??5PPGP5Y5YYJ!~^                  
                .:^!!~7????JJY5555YY55YJ?J?!^.         .^!JYYYJJJ???JJJYYYJYJ7!~^.                  
                  :^^!!!7??JJYYJYYYJJJJ7!~~:             .^7?YYY555JYY5Y5YJJ7!~^:                   
                    .~~~!!!777777??7?7!~^.                 .~!7??JYYYYYYJ?77!!:.                    
                       .^^^^!~~~!~~~^:..                     .:~~~!!7777!~!~::                      
                            .. ..                                ..::::~:...                       
*/

pragma solidity 0.8.15;

import {IZooOfNeuralAutomata} from "../interfaces/IZooOfNeuralAutomata.sol";
import {Owned} from "../../lib/solmate/src/auth/Owned.sol";
import {IERC1155} from "../../lib/forge-std/src/interfaces/IERC1155.sol";
import {IOschuns} from "../interfaces/IOschuns.sol";

contract Oschuns is Owned, IOschuns {

    uint256 constant id = 303;
    uint256 constant duration = 4 hours;

    address public immutable zona;
    uint256 public immutable startTime;

    uint256 public endTime;

    address public topBidder;
    uint256 public topBid = 20;

    bool public initalized;
    bool public settled;

    mapping (address => bool) public bidder;

    constructor(
        address _owner,
        address _zona, 
        uint256 _startTime
    ) Owned(_owner) {
        zona = _zona;
        startTime = _startTime;
        endTime = _startTime + duration;
    }
    
    function bid() external payable {
        require(startTime <= block.timestamp);
        require(endTime > block.timestamp);
        require(msg.value >= nextPrice());

        address oldBidder = topBidder;
        uint256 oldBid = topBid;

        topBidder = msg.sender;
        topBid = msg.value;

        bidder[msg.sender] = true;

        if(endTime - block.timestamp <= 300){
            endTime += 300;
        }
        
        if(!(topBidder == address(0))) {
            (bool success,) = oldBidder.call{value: oldBid}("");
            if(!success){
                emit FailedRefund(oldBidder, oldBid);
            }
        }
    }

    function settle() external {
        require(endTime < block.timestamp);
        require(!settled);
        settled = true;

        IERC1155(zona).safeTransferFrom(address(this), topBidder, id, 3, "");
    }

    function initalize() external onlyOwner {
        require(!initalized);
        initalized = true;
        IZooOfNeuralAutomata(zona).mint(address(this), id, 3);
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    function nextPrice() public view returns(uint256) {
        return topBid + (topBid/20);
    }
}