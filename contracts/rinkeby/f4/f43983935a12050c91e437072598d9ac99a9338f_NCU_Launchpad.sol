/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


// import "./PresaleLaunchpadToken.sol";
// import "./PublicsaleLaunchpadToken.sol";
// import "hardhat/console.sol";

interface PreSale{
      /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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
    

    function contractDetails(
        
        string memory namee,
        string memory symboll,
        uint256 maxSupply,
        uint256 preSaleSupply,
        uint256 maxPerTrans,
        uint256 reserve,
        uint256 price,
        uint256 presalePrice,
        string memory baseuri,
        uint256 maxPerWallet,
        bytes32 root
    )external;

    function initialize(address recepient1)external;

}


interface PublicSale{

function contractDetails(
        
        address recipient1,
        string memory namee,
        string memory symboll,
        uint256 maxSupply,
        uint256 preSaleSupply,
        uint256 maxPerTrans,
        uint256 reserve,
        uint256 price,
        uint256 presalePrice,
        string memory baseuri,
        uint256 maxPerWallet,
        bytes32 root
    )external;

function initialize(address recepient1) external;}


library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000
            )
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}





contract NCU_Launchpad {


    PreSale     preObject;
    // PublicSale  publicObject;



    string public contract_name;
    address public tokenImplementation;
    address public tokenImplementation1;
    uint256 public tax = 2 ether;
    address payable wallet =
    payable(0xc2c7d10B99bf936EffD3cFDD4f5e5f6A6acDDCd3);
    uint256 private counter = 1;
   
    

    struct UserDetails {
        address contractOwner;
        address contractAddress;
        string contractName;
        uint256 createdTime;
        uint256 contractId;
    }


    UserDetails[] public userDataArray;
    mapping(address => mapping(string => UserDetails)) public user_data;
    mapping(address => address) public newContractAddress;
    event TokenDeployed(address tokenAddress);

    constructor(PreSale  oo) {
        preObject=oo;
        tokenImplementation = address(preObject);
        // console.log(tokenImplementation);
        // tokenImplementation1    =   address(new PublicsaleLaunchpadToken());

        contract_name = "cloning factory";
 
    }

    function Clone(
        address recipient1,
        string memory _name,
        string memory _symbol,
        uint256 _maxsupply1,
        uint256 _preSaleSupply,
        uint256 _maxPerTrans,
        uint256 _reserve,
        uint256 _price,
        uint256 _presalePrice,
        string memory _baseuri,
        uint256 _maxPerWallet,
        bytes32 _root
    ) public payable {
        address token = Clones.clone(tokenImplementation);

          newContractAddress[recipient1] = token;

          
            user_data[recipient1][_name] = UserDetails({
            contractOwner: msg.sender,
            contractAddress: token,
            contractName: _name,
            createdTime: block.timestamp,
            contractId: counter
        });
        

        PreSale  obj=PreSale(token);
        obj.initialize(recipient1);
        obj.contractDetails(_name, _symbol,_maxsupply1,_preSaleSupply,_maxPerTrans,_reserve,_price,_presalePrice,_baseuri,_maxPerWallet,_root);
        
        require(tax == msg.value, "enter amount not correct");
        wallet.transfer(msg.value);
     
        
        

               

        UserDetails memory _userDataInstance;
        _userDataInstance.contractOwner = msg.sender;
        _userDataInstance.contractAddress = token;
        _userDataInstance.contractName = _name;
        _userDataInstance.createdTime = block.timestamp;
        _userDataInstance.contractId = counter;
        userDataArray.push(_userDataInstance);



        emit TokenDeployed(token);
        counter++;

   
    }


    //     function ClonePublic(
    //     address recipient1,
    //     string memory _name,
    //     string memory _symbol,
    //     uint256 _maxsupply1,
  
    //     uint256 _maxPerTrans,
    //     uint256 _reserve,
    //     uint256 _price,
       
    //     string memory _baseuri
     
       
    // ) public payable {
    //     address token = Clones.clone(tokenImplementation1);
        
    //     PublicsaleLaunchpadToken(token).contractDetails(
    //         _name,
    //         _symbol,
    //         _maxsupply1,
    //         _maxPerTrans,
    //         _reserve,
    //         _price,
    //         _baseuri
          
    //     );
    //     PresaleLaunchpadToken(token).initialize(recipient1);
    //     newContractAddress[recipient1] = token;
    //     require(tax == msg.value, "enter amount not correct");
    //     wallet.transfer(msg.value);

    //     user_data[recipient1][_name] = UserDetails({
    //         contractOwner: msg.sender,
    //         contractAddress: token,
    //         contractName: _name,
    //         createdTime: block.timestamp,
    //         contractId: counter
    //     });

    //     UserDetails memory _userDataInstance;
    //     _userDataInstance.contractOwner = msg.sender;
    //     _userDataInstance.contractAddress = token;
    //     _userDataInstance.contractName = _name;
    //     _userDataInstance.createdTime = block.timestamp;
    //     _userDataInstance.contractId = counter;
    //     userDataArray.push(_userDataInstance);

    //     emit TokenDeployed(token);
    //     counter++;
    // }













    function getTotalIndexw(address _owner)
        public
        view
        returns (uint256 total)
    {
        uint256 countt = 0;

        for (uint256 index = 0; index < userDataArray.length; index++) {
            if (userDataArray[index].contractOwner == _owner) {
                countt += 1;
            }
        }
        return countt;
    }

    function getCompleteDataOfOwner(address owner)
        public
        view
        returns (
            address[] memory contractAddresses,
            string[] memory _contractname,
            uint256[] memory contract_time
        )
    {
        // Todo storage todo = todos[_index];
        uint256 dyanamicIndex = 0;

        // return (todo.text, todo.completed);
        address[] memory contractAddressArray = new address[](
            getTotalIndexw(owner)
        );
        string[] memory contractName = new string[](getTotalIndexw(owner));
        uint256[] memory timeStampArray = new uint256[](getTotalIndexw(owner));
        // uint[] memory contractIdArray= new uint [] (getTotalIndexw(owner));
        for (uint256 index = 0; index < userDataArray.length; index++) {
            if (userDataArray[index].contractOwner == owner) {
                contractAddressArray[dyanamicIndex] = userDataArray[index]
                    .contractAddress;
                contractName[dyanamicIndex] = userDataArray[index].contractName;
                timeStampArray[dyanamicIndex] = userDataArray[index]
                    .createdTime;
                //   contractIdArray[dyanamicIndex]=userDataArray[index].contractId;
                dyanamicIndex++;
            }
        }
        return (contractAddressArray, contractName, timeStampArray);
    }

    function getcontractID(address owner)
        public
        view
        returns (uint256[] memory id)
    {
        uint256 dyanamicIndex = 0;
        uint256[] memory contractIdArray = new uint256[](getTotalIndexw(owner));

        for (uint256 index = 0; index < userDataArray.length; index++) {
            if (userDataArray[index].contractOwner == owner) {
                contractIdArray[dyanamicIndex] = userDataArray[index]
                    .contractId;
                dyanamicIndex++;
            }
        }
        return (contractIdArray);
    }
}