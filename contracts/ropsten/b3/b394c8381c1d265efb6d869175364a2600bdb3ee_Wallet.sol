/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.14;
interface IWallet {
    function owner() external view returns (address);
    function modules() external view returns (uint);
    function setOwner(address _newOwner) external;
    function authorised(address _module) external view returns (bool);
    function enabled(bytes4 _sig) external view returns (address);
    function authoriseModule(address _module, bool _value) external;
    function enableStaticCall(address _module, bytes4 _method) external;
}

interface IModule {
    function addModule(address _wallet, address _module) external;
    function init(address _wallet) external;
    function supportsStaticCall(bytes4 _methodId) external view returns (bool _isSupported);
}
contract Wallet is IWallet {

    // The owner
    address public override owner;
    // The authorised modules
    mapping (address => bool) public override authorised;
    // module executing static calls
    address public staticCallExecutor;
    // The number of modules
    uint public override modules;

    event AuthorisedModule(address indexed module, bool value);
    event Invoked(address indexed module, address indexed target, uint indexed value, bytes data);
    event Received(uint indexed value, address indexed sender, bytes data);
    event OwnerChanged(address owner);

    /**
     * @notice Throws if the sender is not an authorised module.
     */
    modifier moduleOnly {
        require(authorised[msg.sender], "BW: sender not authorized");
        _;
    }

    /**
     * @notice Inits the wallet by setting the owner and authorising a list of modules.
     * @param _owner The owner.
     * @param _modules The modules to authorise.
     */
    function init(address _owner, address[] calldata _modules) external {
        require(owner == address(0) && modules == 0, "BW: wallet already initialised");
        require(_modules.length > 0, "BW: empty modules");
        owner = _owner;
        modules = _modules.length;
        for (uint256 i = 0; i < _modules.length; i++) {
            require(authorised[_modules[i]] == false, "BW: module is already added");
            authorised[_modules[i]] = true;
            IModule(_modules[i]).init(address(this));
            emit AuthorisedModule(_modules[i], true);
        }
        if (address(this).balance > 0) {
            emit Received(address(this).balance, address(0), "");
        }
    }

    /**
     * @inheritdoc IWallet
     */
    function authoriseModule(address _module, bool _value) external override moduleOnly {
        if (authorised[_module] != _value) {
            emit AuthorisedModule(_module, _value);
            if (_value == true) {
                modules += 1;
                authorised[_module] = true;
                IModule(_module).init(address(this));
            } else {
                modules -= 1;
                require(modules > 0, "BW: cannot remove last module");
                delete authorised[_module];
            }
        }
    }

    /**
    * @inheritdoc IWallet
    */
    function enabled(bytes4 _sig) public view override returns (address) {
        address executor = staticCallExecutor;
        if(executor != address(0) && IModule(executor).supportsStaticCall(_sig)) {
            return executor;
        }
        return address(0);
    }

    /**
    * @inheritdoc IWallet
    */
    function enableStaticCall(address _module, bytes4 /* _method */) external override moduleOnly {
        if(staticCallExecutor != _module) {
            require(authorised[_module], "BW: unauthorized executor");
            staticCallExecutor = _module;
        }
    }

    /**
     * @inheritdoc IWallet
     */
    function setOwner(address _newOwner) external override moduleOnly {
        require(_newOwner != address(0), "BW: address cannot be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }

    /**
     * @notice Performs a generic transaction.
     * @param _target The address for the transaction.
     * @param _value The value of the transaction.
     * @param _data The data of the transaction.
     */
    function invoke(address _target, uint _value, bytes calldata _data) external moduleOnly returns (bytes memory _result) {
        bool success;
        (success, _result) = _target.call{value: _value}(_data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        emit Invoked(msg.sender, _target, _value, _data);
    }

    /**
     * @notice This method delegates the static call to a target contract if the data corresponds
     * to an enabled module, or logs the call otherwise.
     */
    fallback() external payable {
        address module = enabled(msg.sig);
        if (module == address(0)) {
            emit Received(msg.value, msg.sender, msg.data);
        } else {
            require(authorised[module], "BW: unauthorised module");

            // solhint-disable-next-line no-inline-assembly
            assembly {
                calldatacopy(0, 0, calldatasize())
                let result := staticcall(gas(), module, 0, calldatasize(), 0, 0)
                returndatacopy(0, 0, returndatasize())
                switch result
                case 0 {revert(0, returndatasize())}
                default {return (0, returndatasize())}
            }
        }
    }
    receive() external payable {
    }
}