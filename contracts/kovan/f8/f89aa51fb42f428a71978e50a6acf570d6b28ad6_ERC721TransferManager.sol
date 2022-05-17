// SPDX-License-Identifier: AGPL-3.0-only
//
// This contract acts as the universal NFT mover
// this way, users only have to approve one contract to move their NFTs through
// any of our other contracts

import "solmate/tokens/ERC721.sol";
import "Default/Kernel.sol";

pragma solidity >=0.8.7 <0.9.0;

contract ERC721TransferManager is Module {
    constructor(Kernel kernel_) Module(kernel_) {}

    function KEYCODE() public pure override returns (bytes5) {
        return bytes5("NFTMG"); // NFT Manager
    }

    function safeTransferFrom(
        address collection,
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external onlyPermitted {
        ERC721(collection).safeTransferFrom(from, to, tokenId, data);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

abstract contract Module {
    error Module_OnlyApprovedPolicy(address caller_);
    error Module_OnlyPermissionedPolicy(address caller_);

    IKernel public _kernel;

    constructor(IKernel kernel_) {
        _kernel = kernel_;
    }

    function KEYCODE() public pure virtual returns (bytes5) {}

    modifier onlyPermitted() {
        if (_kernel.getWritePermissions(KEYCODE(), msg.sender) == false)
            revert Module_OnlyPermissionedPolicy(msg.sender);
        _;
    }
}

abstract contract Policy {
    error Policy_ModuleDoesNotExist(bytes5 keycode_);
    error Policy_OnlyKernel(address caller_);

    IKernel public _kernel;

    constructor(IKernel kernel_) {
        _kernel = kernel_;
    }

    function getModuleAddress(bytes5 keycode_) internal view returns (address) {
        address moduleForKeycode = _kernel.getModuleForKeycode(keycode_);

        if (moduleForKeycode == address(0))
            revert Policy_ModuleDoesNotExist(keycode_);

        return moduleForKeycode;
    }

    function configureReads() external virtual onlyKernel {}

    function requestWrites()
        external
        view
        virtual
        onlyKernel
        returns (bytes5[] memory permissions)
    {}

    modifier onlyKernel() {
        if (msg.sender != address(_kernel))
            revert Policy_OnlyKernel(msg.sender);
        _;
    }
}

enum Actions {
    InstallModule,
    UpgradeModule,
    ApprovePolicy,
    TerminatePolicy,
    ChangeExecutor
}

struct Instruction {
    Actions action;
    address target;
}

// Core kernel functions for modules and policies to work
interface IKernel {
    function getWritePermissions(bytes5 keycode_, address caller_)
        external
        view
        returns (bool);

    function getModuleForKeycode(bytes5 keycode_)
        external
        view
        returns (address);

    function executeAction(Actions action_, address target_) external;
}

contract Kernel is IKernel {
    event Kernel_WritePermissionsUpdated(
        bytes5 indexed keycode_,
        address indexed policy_,
        bool enabled_
    );

    error Kernel_OnlyExecutor(address caller_);
    error Kernel_ModuleAlreadyInstalled(bytes5 module_);
    error Kernel_ModuleAlreadyExists(bytes5 module_);
    error Kernel_PolicyAlreadyApproved(address policy_);
    error Kernel_PolicyNotApproved(address policy_);

    address public executor;

    constructor() {
        executor = msg.sender;
    }

    modifier onlyExecutor() {
        if (msg.sender != executor) revert Kernel_OnlyExecutor(msg.sender);
        _;
    }

    ///////////////////////////////////////////////////////////////////////////////////////
    //                                 DEPENDENCY MANAGEMENT                             //
    ///////////////////////////////////////////////////////////////////////////////////////

    mapping(bytes5 => address) public getModuleForKeycode; // get contract for module keycode
    mapping(address => bytes5) public getKeycodeForModule; // get module keycode for contract
    mapping(address => bool) public approvedPolicies; // whitelisted apps
    mapping(bytes5 => mapping(address => bool)) public getWritePermissions; // can module (bytes5) be written to by policy (address)
    address[] public allPolicies;

    event ActionExecuted(Actions action_, address target_);

    function executeAction(Actions action_, address target_)
        external
        onlyExecutor
    {
        if (action_ == Actions.InstallModule) {
            _installModule(target_);
        } else if (action_ == Actions.UpgradeModule) {
            _upgradeModule(target_);
        } else if (action_ == Actions.ApprovePolicy) {
            _approvePolicy(target_);
        } else if (action_ == Actions.TerminatePolicy) {
            _terminatePolicy(target_);
        } else if (action_ == Actions.ChangeExecutor) {
            // Require kernel to install the EXCTR module before calling ChangeExecutor on it
            if (getKeycodeForModule[target_] != "EXCTR")
                revert Kernel_OnlyExecutor(target_);

            executor = target_;
        }

        emit ActionExecuted(action_, target_);
    }

    function _installModule(address newModule_) internal {
        bytes5 keycode = Module(newModule_).KEYCODE();

        // @NOTE check newModule_ != 0
        if (getModuleForKeycode[keycode] != address(0))
            revert Kernel_ModuleAlreadyInstalled(keycode);

        getModuleForKeycode[keycode] = newModule_;
        getKeycodeForModule[newModule_] = keycode;
    }

    function _upgradeModule(address newModule_) internal {
        bytes5 keycode = Module(newModule_).KEYCODE();
        address oldModule = getModuleForKeycode[keycode];

        if (oldModule == address(0) || oldModule == newModule_)
            revert Kernel_ModuleAlreadyExists(keycode);

        getKeycodeForModule[oldModule] = bytes5(0);
        getKeycodeForModule[newModule_] = keycode;
        getModuleForKeycode[keycode] = newModule_;

        _reconfigurePolicies();
    }

    function _approvePolicy(address policy_) internal {
        if (approvedPolicies[policy_] == true)
            revert Kernel_PolicyAlreadyApproved(policy_);

        approvedPolicies[policy_] = true;

        Policy(policy_).configureReads();

        bytes5[] memory permissions = Policy(policy_).requestWrites();
        _setWritePermissions(policy_, permissions, true);

        allPolicies.push(policy_);
    }

    function _terminatePolicy(address policy_) internal {
        if (approvedPolicies[policy_] == false)
            revert Kernel_PolicyNotApproved(policy_);

        approvedPolicies[policy_] = false;

        bytes5[] memory permissions = Policy(policy_).requestWrites();
        _setWritePermissions(policy_, permissions, false);
    }

    function _reconfigurePolicies() internal {
        for (uint256 i = 0; i < allPolicies.length; i++) {
            address policy_ = allPolicies[i];

            if (approvedPolicies[policy_] == true)
                Policy(policy_).configureReads();
        }
    }

    function _setWritePermissions(
        address policy_,
        bytes5[] memory keycodes_,
        bool canWrite_
    ) internal {
        for (uint256 i = 0; i < keycodes_.length; i++) {
            getWritePermissions[keycodes_[i]][policy_] = canWrite_;
            emit Kernel_WritePermissionsUpdated(
                keycodes_[i],
                policy_,
                canWrite_
            );
        }
    }
}