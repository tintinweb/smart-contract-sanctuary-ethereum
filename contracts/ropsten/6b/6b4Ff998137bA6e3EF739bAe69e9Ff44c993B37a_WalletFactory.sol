// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface Implementation {
    function initialize(address[] memory _owners, uint _numConfirmationsRequired, address _bank) external;
}

/// @dev this is the contract handling the cloning and storing the address of all the clone wallet
contract WalletFactory {
    address public admin;
    address private implementation; // addres of the implementation contract

    // wallet_addr => array_of_owners
    mapping (address => address[]) private wallets;


    constructor(address _imp) {
        admin = msg.sender;
        implementation = _imp;
    }


    event Cloned(address deployer, address newContract);


    // CUSTOM ERRORS
    

    /// You are not an admin
    error OnlyAdmin();


    /// Owners Cannot Be Empty
    error OwnersCannotBeEmpty();

    /// Number of comfirmations must be greater that zero
    error ComfirmationMustBeGreaterThanZero();




    // MODIFIERS
    modifier MustBeAdmin() {
        if(msg.sender != admin) {
            revert OnlyAdmin();
        }
        _;
    }



    function getImplementationAddress() public view MustBeAdmin returns (address) {
        return implementation;
    }

    

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`. (Implemented witht he create opcode)
     */
    function _clone(address _implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, _implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }


    function clone(address[] memory _owners, uint _numConfirmationsRequired, address _bank) external returns (address ) {
        // the input owner must be more than zero
        if (_owners.length == 0) {
            revert OwnersCannotBeEmpty();
        }

        if(_numConfirmationsRequired == 0) {
            revert ComfirmationMustBeGreaterThanZero();
        }

        address newWallet = _clone(implementation);

        // storing thely created wallet to the mapping 
        wallets[newWallet] = _owners;
        Implementation(newWallet).initialize(_owners, _numConfirmationsRequired, _bank);

        emit Cloned(msg.sender, newWallet);

        return newWallet;
    }



    function getWalletOwners(address _wallet_contract_addrs) public view returns (address[] memory) {
        return wallets[_wallet_contract_addrs];
    }
}