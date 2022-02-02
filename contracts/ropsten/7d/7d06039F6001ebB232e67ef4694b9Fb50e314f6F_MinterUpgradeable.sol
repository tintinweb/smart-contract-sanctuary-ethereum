pragma solidity ^0.7.6;
pragma abicoder v2;

import "./../tokens/@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "./../tokens/@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./../tokens/@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./../tokens/@openzeppelin/contracts-upgradeable/introspection/ERC165Upgradeable.sol";
import "./../tokens/@rarible/libraries/contracts/LibSignature.sol";
import "./../tokens/erc-1271/ERC1271.sol";
import "./IMinterUpgradeable.sol";
import "./LibMinter.sol";
import "./RolesValidator.sol";
import "../tokens/@rarible/royalties/contracts/LibPart.sol";
import "./../tokens/SplitPayments.sol";

contract MinterUpgradeable is ERC1271, OwnableUpgradeable, ERC165Upgradeable, IMinterUpgradeable, RolesValidator {

    using LibSignature for bytes32;
    using AddressUpgradeable for address;

    event UpsertDefaultMinter(address indexed minter, uint96 fee, bool active);
    event MinDefaultMinterRoyalty(uint96 fee);
    event UpsertDefaultPayouts(address indexed token, address indexed creator, LibPart.Part[] creators, bool byOwner);
    event UpsertDefaultRoyalties(address indexed token, address indexed creator, bytes32 royaltyBytes, bool byOwner);
    event NewSplitter(LibPart.Part[] payees, bytes32 splitterBytes, address indexed splitterAddress); // @todo find better word for depositBPS
    event RecievedRoyaltyPayment(address indexed from, uint256 amount);
    event WithdrawStakedRoyalty(address indexed splitter, address indexed by, uint256 amount, LibPart.Part[] splits);
    event UpsertMinter(address indexed token, address indexed creator, address indexed minter, bool active, uint96 fee, uint256 cancelValue);

    struct Minter {
        bool active;
        uint96 fee;
        uint256 cancelValue;
        uint256 start;
        uint256 end;
        LibPart.Part[] creators;    // No need to create splitter for creator payouts
        bytes32 royalties;          // Creating a splitter to allow for EIP 2981
    }

    struct DefaultMinter {
        bool active;
        uint96 fee;
        uint256 cancelValue;
        uint256 start;
        uint256 end;
    }

    // Store the royalty stakes from the wallets
    mapping(address => uint256) public stake;

    // Default minter
    // address private minter;
    // uint96 private fee;
    mapping(address => uint256) private defaults;
    // Creator approved minters
    mapping(address => mapping(address => mapping(address => uint256))) private minters;

    // Minters registry
    DefaultMinter[] public defaultsRegistry;
    Minter[] public mintersRegistry;

    // To map created payment splitters with their definition, used for custom minters
    address public splitterImplementationContract;
    mapping (bytes32 => LibPart.Part) public splitters;

    // Maps splitter address to whom the staked amount should go to
    mapping (address => LibPart.Part[]) public withdrawSplits;
    // Overall percentage basis points excluding the minter contract
    mapping (address => uint96) public depositBPS;

    // Mapping from creator to payment splitter for default royalties
    mapping (address => mapping(address => LibPart.Part[] )) public defaultPayoutMapping;
    mapping (address => mapping(address => bytes32)) public defaultRoyaltySplittersMapping;

    // Minimum royalty for using the default signer
    uint96 public minDefaultMinterRoyalty;

    function __MinterUpgradable_init (address _minter, uint96 _fee, uint96 _minDefaultMinterRoyalty, address _splitterImplementationContract ) public initializer {
        __Ownable_init();
        __ERC165_init_unchained();
        _registerInterface(ERC1271_INTERFACE_ID);

        // Ensure index 0 is empty by default for cases where data is not set
        defaultsRegistry.push();
        mintersRegistry.push();

        upsertDefaultMinter(_minter, _fee, true);
        setMinDefaultMinterRoyalty(_minDefaultMinterRoyalty);
        setSplitterImplementationContract(_splitterImplementationContract);
    }

    function setSplitterImplementationContract(address _splitterImplementationContract) public onlyOwner {
        splitterImplementationContract = _splitterImplementationContract;
    }
    
    function setMinDefaultMinterRoyalty(uint96 _minDefaultMinterRoyalty) public onlyOwner {
        minDefaultMinterRoyalty = _minDefaultMinterRoyalty;
        emit MinDefaultMinterRoyalty(_minDefaultMinterRoyalty);
    }

    function upsertDefaultMinter(address _minter, uint96 _fee, bool active ) public onlyOwner {
        defaults[_minter] = defaultsRegistry.length;
        defaultsRegistry.push(DefaultMinter(active, _fee, 0, 0, 0));
        emit UpsertDefaultMinter(_minter, _fee, active);
    }

    function upsertDefaultCreatorPayoutsAndRoyalties(LibMinter.DefaultMinter memory data) public onlyOwner {

        delete defaultPayoutMapping[data.token][data.creator];
        for (uint i = 0; i < data.creators.length; i++) {
            defaultPayoutMapping[data.token][data.creator].push(data.creators[i]);
        }
        bytes32 royaltiesBytes = getOrCreateSplitterUsingSplit(data.royalties);
        defaultRoyaltySplittersMapping[data.token][data.creator] = royaltiesBytes;

        emit UpsertDefaultPayouts(data.token, data.creator, data.creators, true);
        emit UpsertDefaultRoyalties(data.token, data.creator, royaltiesBytes, true);

    }

    function upsertDefaultCreatorPayoutsAndRoyaltiesByCreator(LibMinter.DefaultMinter memory data) public {

        require(data.creator == _msgSender(), "Can't set for someone else");
        delete defaultPayoutMapping[data.token][data.creator];
        for (uint i = 0; i < data.creators.length; i++) {
            defaultPayoutMapping[data.token][data.creator].push(data.creators[i]);
        }

        // Ensure Minters contract gets a minimum specified royalty
        bool setDefault;
        for (uint i = 0; i < data.royalties.length; i++) {
            if (data.royalties[i].account == address(this)){
                if (data.royalties[i].value < minDefaultMinterRoyalty) {
                    data.royalties[i].value = minDefaultMinterRoyalty;
                }
                setDefault = true;
                break;
            }
        }

        bytes32 royaltiesBytes;
        if (!setDefault){
            // Extend array in memory
            LibPart.Part[] memory royalties = new LibPart.Part[](data.royalties.length + 1);
            for (uint i = 0; i < data.royalties.length; i++) {
                royalties[i].account = data.royalties[i].account;
                royalties[i].value = data.royalties[i].value;
            }
            royalties[data.royalties.length].account = payable(address(this));
            royalties[data.royalties.length].value = minDefaultMinterRoyalty;

            royaltiesBytes = getOrCreateSplitterUsingSplit(royalties);
            defaultRoyaltySplittersMapping[data.token][data.creator] = royaltiesBytes;
        } else {
            royaltiesBytes = getOrCreateSplitterUsingSplit(data.royalties);
            defaultRoyaltySplittersMapping[data.token][data.creator] = royaltiesBytes;
        }

        emit UpsertDefaultPayouts(data.token, data.creator, data.creators, false);
        emit UpsertDefaultRoyalties(data.token, data.creator, royaltiesBytes, false);
    }

    function getDefaultMinter(address _minter) external view returns (uint256 index, DefaultMinter memory) {
        return (defaults[_minter], defaultsRegistry[defaults[_minter]]);
    }

    function getDefaultMinterFee(address _minter) public view returns (uint96) {
        return defaultsRegistry[defaults[_minter]].fee;
    }

    function getOrCreateSplitterUsingSplit(LibPart.Part[] memory payees) internal virtual returns (bytes32){

        address payable splitterAddress;
        uint96 totalValue;
        bytes32 splitterBytes = LibPart.hashParts(payees);
        if (payees.length == 1) {
            require(payees[0].account != address(0x0), "Recipient should be present");
            require(payees[0].value != 0, "Royalty value should be positive");
            require(payees[0].value < 10000, "Royalty total value should be < 10000");

            splitters[splitterBytes] = LibPart.Part(payees[0].account, payees[0].value);

        } else if ( payees.length > 0) {
            splitterAddress = splitters[splitterBytes].account;
            totalValue = splitters[splitterBytes].value;
            
            // Check if splitter is not already created
            if (splitterAddress == address(0x0)){

                
                for (uint i = 0; i < payees.length; i++) {
                    require(payees[i].account != address(0x0), "Recipient should be present");
                    require(payees[i].value != 0, "Royalty value should be positive");
                    totalValue += payees[i].value;
                }
                require(totalValue < 10000, "Royalty total value should be < 10000");

                uint96 _depositBPS;
                for (uint i = 0; i < payees.length; i++) {
                    payees[i].value = payees[i].value * 10000 / totalValue;
                    if (payees[i].account != address(this)){
                        _depositBPS += payees[i].value;
                    } else {
                        payees[i].value = 0;
                    }
                }

                splitterAddress = payable(ClonesUpgradeable.clone(splitterImplementationContract));
                SplitPayments(splitterAddress).setMinterContract(address(this));

                splitters[splitterBytes] = LibPart.Part(splitterAddress, totalValue);
                depositBPS[splitterAddress] = _depositBPS;

                for (uint i = 0; i < payees.length; i++){
                    withdrawSplits[splitterAddress].push(payees[i]);
                }

                emit NewSplitter(payees, splitterBytes, splitterAddress);

            }

            // return LibPart.Part(payable(splitter), totalValue);
        }

        return splitterBytes;
    }

    function recieveRoyaltyStake() external payable override {
        require(depositBPS[_msgSender()] > 0, "Isn't a splitter address");
        // Stake the royalty users into their staked wallet address to be withdrawn when they want
        // The minterDefault's stake is just added to the contract balance
        stake[_msgSender()] += msg.value * depositBPS[_msgSender()] / 10000 ;
        stake[owner()] += msg.value * (10000 - depositBPS[_msgSender()]) / 10000 ;
        emit RecievedRoyaltyPayment(_msgSender(), msg.value);
    }

    function withdrawOwnerStake() external onlyOwner {
        (bool success, ) = owner().call{value: stake[owner()]}("");
        require(success, "Transfer failed.");
    }

    function withdrawRoyaltyStake(bytes32 splitterBytes) external {
        address splitterAddress = splitters[splitterBytes].account;
        // Send the staked amounts to participants wallets
        for (uint i = 0; i < withdrawSplits[splitterAddress].length; i++) {
            if (withdrawSplits[splitterAddress][i].account != address(this)) {
                (bool success, ) = withdrawSplits[splitterAddress][i].account.call{
                value:(stake[splitterAddress] * withdrawSplits[splitterAddress][i].value ) / depositBPS[splitterAddress]
                }("");
                // require(success, "Transfer failed."); // If someone messed up, others shouldn't suffer
            }
        }
        emit WithdrawStakedRoyalty(splitterAddress, _msgSender(), stake[splitterAddress], withdrawSplits[splitterAddress]);
        delete stake[splitterAddress];
    }

    function upsertMinter(address _token, LibMinter.Minter memory data) public virtual {

        bytes32 hash = LibMinter.hash(data);

        // Check if creator and minter gave signature
        address signer = validate(data.minter, hash, data.signatures[0]);
        validate(data.creator, hash, data.signatures[1]);

        // Creator is free to choose royalty split
        bytes32 royalties = getOrCreateSplitterUsingSplit(data.royalties);
        minters[_token][data.creator][data.minter] = mintersRegistry.length;

        
        mintersRegistry.push();

        mintersRegistry[mintersRegistry.length - 1].active = true;
        mintersRegistry[mintersRegistry.length - 1].fee = data.fee;
        mintersRegistry[mintersRegistry.length - 1].cancelValue = data.cancelValue;
        mintersRegistry[mintersRegistry.length - 1].start = data.start;
        mintersRegistry[mintersRegistry.length - 1].end = data.end;
        mintersRegistry[mintersRegistry.length - 1].royalties = royalties;

        for (uint i = 0; i < data.creators.length; i++) {
            mintersRegistry[mintersRegistry.length - 1].creators.push(data.creators[i]);
        }

        emit UpsertMinter(_token, data.creator, data.minter, true, data.fee, data.cancelValue);

    }

    function cancelMinter(address _token, address _minter) public payable virtual {
        require(
            msg.value == mintersRegistry[minters[_token][_msgSender()][_minter]].cancelValue,
            "Cancel charge"
        );
        delete mintersRegistry[minters[_token][_msgSender()][_minter]].active;
        emit UpsertMinter(_token, _msgSender(), _minter, false, 0, 0);
    }

    function getMinter(address _token, address _creator, address _minter)
        public
        view
        virtual
        returns (Minter memory)
    {
        return mintersRegistry[minters[_token][_creator][_minter]];
    }


    function getDetailsForMinting(address _token, address _creator, address _signer) external view virtual override returns (
        uint96,                 // Minting fee
        LibPart.Part[] memory,  // Creators payouts
        bytes32,                // Royalty splitter contract bytes to save
        LibPart.Part memory     // Royalty splitter contract address and percentage basis points
    ){
       
        if (_signer == _creator){
            // Allowing self signed
            if (defaultPayoutMapping[_token][_creator].length == 0){
                LibPart.Part[] memory creators = new LibPart.Part[](1);
                creators[0].account = payable(_creator);
                creators[0].value  = 10000;

                return (0, 
                        creators, 
                        defaultRoyaltySplittersMapping[_token][_creator], 
                        splitters[defaultRoyaltySplittersMapping[_token][_creator]]);
            }

            return (0, 
                    defaultPayoutMapping[_token][_creator], 
                    defaultRoyaltySplittersMapping[_token][_creator], 
                    splitters[defaultRoyaltySplittersMapping[_token][_creator]]);

        } else if (mintersRegistry[minters[_token][_creator][_signer]].active) {
            
            // Signed by creator defined minter
            return (mintersRegistry[minters[_token][_creator][_signer]].fee, 
                    mintersRegistry[minters[_token][_creator][_signer]].creators, 
                    mintersRegistry[minters[_token][_creator][_signer]].royalties, 
                    splitters[mintersRegistry[minters[_token][_creator][_signer]].royalties]);

        } else if (defaultsRegistry[defaults[_signer]].active) {

            // Signed by any of the default minters
            if (defaultPayoutMapping[_token][_creator].length == 0){
                LibPart.Part[] memory creators = new LibPart.Part[](1);
                creators[0].account = payable(_creator);
                creators[0].value  = 10000;

                return (defaultsRegistry[defaults[_signer]].fee, 
                        creators, 
                        defaultRoyaltySplittersMapping[_token][_creator], 
                        splitters[defaultRoyaltySplittersMapping[_token][_creator]]);
            } 

            return (defaultsRegistry[defaults[_signer]].fee, 
                    defaultPayoutMapping[_token][_creator], 
                    defaultRoyaltySplittersMapping[_token][_creator], 
                    splitters[defaultRoyaltySplittersMapping[_token][_creator]]);
        }
        revert("Illegal minter");
    }


    function getDetailsForRoyalty(address _token, address _creator, address _signer) external view virtual override returns (
        bytes32 // Splitter description bytes identifier for the wallet
    ){
        if (_signer == _creator){
            return defaultRoyaltySplittersMapping[_token][_creator];
        } else if (mintersRegistry[minters[_token][_creator][_signer]].active) {
            return mintersRegistry[minters[_token][_creator][_signer]].royalties;
        } else if (defaultsRegistry[defaults[_signer]].active) {
            return defaultRoyaltySplittersMapping[_token][_creator];
        }
        revert("Illegal minter");
    }

    function getSplitter(bytes32 splitterBytes) external view override returns(LibPart.Part memory) {
        return splitters[splitterBytes];
    }

    


    /**
    * @dev Function must be implemented by deriving contract
    * @param _hash Arbitrary length data signed on the behalf of address(this)
    * @param _signature Signature byte array associated with _data
    * @return A bytes4 magic value 0x1626ba7e if the signature check passes, 0x00000000 if not
    *
    * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    * MUST allow external calls
    */
    function isValidSignature(bytes32 _hash, bytes memory _signature) public virtual override view returns (bytes4){

        address signerFromSig;
        if (_signature.length == 65) {
            signerFromSig = _hash.recover(_signature);
            if (defaultsRegistry[defaults[signerFromSig]].active) {
                return returnIsValidSignatureMagicNumber(true);
            }
        }
        return returnIsValidSignatureMagicNumber(false);

    }


    uint256[50] private __gap;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _setOwnership(msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwnership(address(0));
    }

    function _setOwnership(address newOwner) internal virtual {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwnership(newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165Upgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

library LibSignature {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );

        // If the signature is valid (and not malleable), return the signer address
        // v > 30 is a special case, we need to adjust hash with "\x19Ethereum Signed Message:\n32"
        // and v = v - 4
        address signer;
        if (v > 30) {
            require(
                v - 4 == 27 || v - 4 == 28,
                "ECDSA: invalid signature 'v' value"
            );
            signer = ecrecover(toEthSignedMessageHash(hash), v - 4, r, s);
        } else {
            require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");
            signer = ecrecover(hash, v, r, s);
        }

        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

abstract contract ERC1271 {
    bytes4 constant public ERC1271_INTERFACE_ID = 0xfb855dc9; // this.isValidSignature.selector

    bytes4 constant public ERC1271_RETURN_VALID_SIGNATURE =   0x1626ba7e;
    bytes4 constant public ERC1271_RETURN_INVALID_SIGNATURE = 0x00000000;

    /**
    * @dev Function must be implemented by deriving contract
    * @param _hash Arbitrary length data signed on the behalf of address(this)
    * @param _signature Signature byte array associated with _data
    * @return A bytes4 magic value 0x1626ba7e if the signature check passes, 0x00000000 if not
    *
    * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
    * MUST allow external calls
    */
    function isValidSignature(bytes32 _hash, bytes memory _signature) public virtual view returns (bytes4);

    function returnIsValidSignatureMagicNumber(bool isValid) internal pure returns (bytes4) {
        return isValid ? ERC1271_RETURN_VALID_SIGNATURE : ERC1271_RETURN_INVALID_SIGNATURE;
    }
}

pragma solidity ^0.7.6;
pragma abicoder v2;

import "../tokens/@rarible/royalties/contracts/LibPart.sol";

interface IMinterUpgradeable {

    function getDetailsForMinting(address _token, address _creator, address _signer) external view returns (
        uint96,
        LibPart.Part[] memory,
        bytes32,
        LibPart.Part memory);

    function getDetailsForRoyalty(address _token, address _creator, address _signer) external view returns (
        bytes32
    );

    function getSplitter(bytes32 signature) external view returns(LibPart.Part memory);

    function recieveRoyaltyStake() external payable;
}

pragma solidity >=0.6.2 <0.8.0;
pragma abicoder v2;


import "../tokens/@rarible/royalties/contracts/LibPart.sol";

// https://medium.com/coinmonks/eip712-a-full-stack-example-e12185b03d54
library LibMinter {

    bytes32 constant MINTER_FEE_TYPEHASH = keccak256(
        "Minter(address minter,address creator,address token,uint96 fee,uint256 cancelValue,uint256 start,uint256 end,Part[] creators,Part[] royalties)Part(address account,uint96 value)"
    );

    struct Minter {
        address minter;
        address creator;
        address token;
        uint96 fee;
        uint256 cancelValue;
        uint start;
        uint end;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
        bytes[] signatures;
    }

    struct DefaultMinter {
        address creator;
        address token;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
    }

    function hash(Minter memory minter) internal pure returns (bytes32) {

        bytes32[] memory royaltiesBytes = new bytes32[](minter.royalties.length);
        for (uint256 i = 0; i < minter.royalties.length; i++) {
            royaltiesBytes[i] = LibPart.hash(minter.royalties[i]);
        }
        bytes32[] memory creatorsBytes = new bytes32[](minter.creators.length);
        for (uint256 i = 0; i < minter.creators.length; i++) {
            creatorsBytes[i] = LibPart.hash(minter.creators[i]);
        }

        bytes32 hashStruct = keccak256(abi.encode(
            MINTER_FEE_TYPEHASH,
            minter.minter,
            minter.creator,
            minter.token,
            minter.fee,
            minter.cancelValue,
            minter.start,
            minter.end,
            keccak256(abi.encodePacked(creatorsBytes)),
            keccak256(abi.encodePacked(royaltiesBytes))
        ));

        return hashStruct;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "./../tokens/erc-1271/ERC1271Validator.sol";

contract RolesValidator is ERC1271Validator {
    function __RolesValidator_init_unchained() internal initializer {
        __EIP712_init_unchained("Roles", "1");
    }

    function validate(address account, bytes32 hash, bytes memory signature) internal view returns(address) {
        return validate1271(account, hash, signature);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");
    bytes32 public constant ARRAY_TYPE_HASH = keccak256("Parts(Part[] parts)Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
    
    function hashParts(Part[] memory parts) internal pure returns (bytes32) {
        bytes32[] memory partsBytes = new bytes32[](parts.length);
        for (uint256 i = 0; i < parts.length; i++) {
            partsBytes[i] = LibPart.hash(parts[i]);
        }
        return keccak256(abi.encode(ARRAY_TYPE_HASH, keccak256(abi.encodePacked(partsBytes))));
    }

}

pragma solidity 0.7.6;

import "./IMinterUpgradeableFPaymentSplitter.sol";
import "./../tokens/@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract SplitPayments is Initializable {

    IMinterUpgradeableFPaymentSplitter minter;

    constructor() public {
    }

    function setMinterContract(address minterAddress) external initializer {
        minter = IMinterUpgradeableFPaymentSplitter(minterAddress);
    }

    receive() external payable {
        minter.recieveRoyaltyStake{value: address(this).balance}();
    }
    fallback() external payable {
        minter.recieveRoyaltyStake{value: address(this).balance}();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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
interface IERC165Upgradeable {
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

pragma solidity 0.7.6;

import "./ERC1271.sol";
import "./../@openzeppelin/contracts-upgradeable/drafts/EIP712Upgradeable.sol";
import "./../@rarible/libraries/contracts/LibSignature.sol";

abstract contract ERC1271Validator is EIP712Upgradeable {
    using AddressUpgradeable for address;
    using LibSignature for bytes32;

    string constant SIGNATURE_ERROR = "signature verification error";
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;

    function validate1271(address signer, bytes32 structHash, bytes memory signature) internal view returns (address) {
        bytes32 hash = _hashTypedDataV4(structHash);

        address signerFromSig;
        if (signature.length == 65) {
            signerFromSig = hash.recover(signature);
        }
        if  (signerFromSig != signer) {
            if (signer.isContract()) {
                require(
                    ERC1271(signer).isValidSignature(hash, signature) == MAGICVALUE,
                    SIGNATURE_ERROR
                );
            } else {
                revert(SIGNATURE_ERROR);
            }
        }

        return signerFromSig;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal initializer {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal initializer {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(bytes32 typeHash, bytes32 name, bytes32 version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                typeHash,
                name,
                version,
                _getChainId(),
                address(this)
            )
        );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash));
    }

    function _getChainId() private view returns (uint256 chainId) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }
    uint256[50] private __gap;
}

pragma solidity ^0.7.6;

interface IMinterUpgradeableFPaymentSplitter {
    function recieveRoyaltyStake() external payable;
}