// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;
// import "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import { IENS } from './interfaces/IENS.sol';
import { IStarkNetLike } from './interfaces/IStarkNetLike.sol';

contract MessageENS {
     // The StarkNet core contract.
    IStarkNetLike _starknetLike;
    IENS _ens;
    address private _adminSigner;
    address private _ensaddress;    
    address private _starknet;
    mapping (string => address) public owner_lists;

    // https://goerli.etherscan.io/address/0x57f1887a8bf19b14fc0df6fd9b2acc9af147ea85#code
    bytes32 public baseNode = 0x93cdeb708b7545dc668eb9280176169d1c33cfd8ed6f04690a0bcc88a93fc4ae;

    // The selector of the "create_philand" l1_handler.
    uint256 constant CREATE_PHILAND_SELECTOR =
        617099311689109934115201364618365113888900634692095419483864089403220532029;

    uint256 constant CLAIM_L1_OBJECT_SELECTOR =
        1426524085905910661260502794228018787518743932072178038305015687841949115798;

    uint256 constant CLAIM_L2_OBJECT_SELECTOR =
    725729645710710348624275617047258825327720453914706103365608274738200251740;

    error InvalidENS (address sender, string name,uint256 ensname, bytes32 label,address owner, string node);

    event LogCreatePhiland(address indexed l1Sender, string name);
    event LogClaimL1NFT(string name,uint256 contract_address,uint256 tokenid);
    event LogClaimL2Object(string name,uint256 l2user_address, uint256 tokenid);
    
    struct Coupon {
    bytes32 r;
    bytes32 s;
    uint8 v;
    }

    /**
      Initializes the contract state.
    */
    constructor(address starknet,IENS ens,address adminSigner){
        
        _starknet = starknet;
        _ens = ens;
        _adminSigner = adminSigner;
        
    }

    //todo ens check and set ens method
    function createPhiland(
        uint256 l2ContractAddress,
        string memory name
        ) external {

        bytes32 label = keccak256(abi.encodePacked(baseNode, keccak256(bytes(name))));
        uint256 ensname = uint256(stringToBytes32(name));
        
        if (msg.sender != _ens.owner(label)){
            revert InvalidENS({
                sender: msg.sender,
                name: name,
                ensname: ensname,
                label: label,
                owner: _ens.owner(label),
                node: string(abi.encodePacked(ensname))
            });
        }

        owner_lists[name]=msg.sender;

        emit LogCreatePhiland(msg.sender, name);
        uint256[] memory payload = new uint256[](1);
        payload[0] = ensname;

        // Send the message to the StarkNet core contract.
        IStarkNetLike(_starknet).sendMessageToL2(l2ContractAddress, CREATE_PHILAND_SELECTOR, payload);
    }

    function claimL1Object(
        uint256 l2ContractAddress,
        string memory name,
        address contractAddress,
        uint256 tokenid
        ) external {

        emit LogClaimL1NFT(name,uint256(uint160(contractAddress)),tokenid);        
        uint256[] memory payload = new uint256[](3);
        payload[0] = uint256(stringToBytes32(name));
        payload[1] = uint256(uint160(contractAddress));
        payload[2] = tokenid;

        // Send the message to the StarkNet core contract.
        IStarkNetLike(_starknet).sendMessageToL2(l2ContractAddress, CLAIM_L1_OBJECT_SELECTOR, payload);
    }

    // enum CouponType {
    // lootbalance,
    // uniswap1,
    // uniswap5,
    // uniswap10,
    // snapshot,
    // ethbalance1
    // }
    
    mapping (string => uint256) public coupon_type;

    function getCouponType(string calldata condition) view public returns (uint256){
        return coupon_type[condition];
    }

    function setCouponType(string calldata condition,uint256 tokenid) public {
        coupon_type[condition] = tokenid;
    }

    function claimL2Object(
        uint256 l2ContractAddress,
        string memory name,
        uint256 l2UserAddress,
        uint256 tokenid,
        string calldata condition,
        Coupon memory coupon
        ) external {

        bytes32 digest = keccak256(
        abi.encode(coupon_type[condition], msg.sender)
        ); 
    
        require(
        _isVerifiedCoupon(digest, coupon), 
        'Invalid coupon'
        ); 
        emit LogClaimL2Object(name,l2UserAddress,tokenid);
        
        uint256[] memory payload = new uint256[](4);
        payload[0] = uint256(stringToBytes32(name));
        payload[1] = l2UserAddress;
        (payload[2], payload[3])=toSplitUint(tokenid);

        
        // Send the message to the StarkNet core contract.
        IStarkNetLike(_starknet).sendMessageToL2(l2ContractAddress, CLAIM_L2_OBJECT_SELECTOR, payload);
    }

    function OwnerOfPhiland(string memory name) external view returns (bool){
        if (owner_lists[name]!=address(0))
            return true;
        else
            return false;
    }

    /// @dev check that the coupon sent was signed by the admin signer
	function _isVerifiedCoupon(bytes32 digest, Coupon memory coupon)
		internal
		view
		returns (bool)
	{
		
		address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
		require(signer != address(0), 'ECDSA: invalid signature'); // Added check for zero address
		return signer == _adminSigner;
	}


    function toSplitUint(uint256 value) internal pure returns (uint256, uint256) {
    uint256 low = value & ((1 << 128) - 1);
    uint256 high = value >> 128;
    return (low, high);
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
    uint256 constant DEPOSIT_SELECTOR =
        352040181584456735608515580760888541466059565068553383579463728554843487745;

     function deposit(
        uint256 l2ContractAddress,
        uint256 user,
        uint256 amount
    ) external {
        // require(amount < 2**64, "Invalid amount.");
        // require(amount <= userBalances[user], "The user's balance is not large enough.");

        // // Update the L1 balance.
        // userBalances[user] -= amount;

        // Construct the deposit message's payload.
        uint256[] memory payload = new uint256[](2);
        payload[0] = user;
        payload[1] = amount;

        // Send the message to the StarkNet core contract.
        IStarkNetLike(_starknet).sendMessageToL2(l2ContractAddress, DEPOSIT_SELECTOR, payload);
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;


interface IENS {
    function resolver(bytes32 node) external view returns (Resolver);
    function owner(bytes32 node) external view returns (address);
}

abstract contract Resolver {
    function addr(bytes32 node) public virtual view returns (address);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.8;

interface IStarkNetLike {
    /**
      Sends a message to an L2 contract.
      Returns the hash of the message.
    */
    function sendMessageToL2(
        uint256 to_address,
        uint256 selector,
        uint256[] calldata payload
    ) external;
}