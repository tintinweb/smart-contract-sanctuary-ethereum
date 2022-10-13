// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;
import "./types/Ownable.sol";


/// @notice this contract is used to handle storing bonds deatils 
contract OlympusProFactoryStorage is Ownable {
    
    /**
     * ===================================================
     * ----------------- STRUCT --------------------------
     * ===================================================
     */

    struct BondDetails {
        address _principalToken;
        address _treasuryAddress;
        address _bondAddress;
        address _stakingAddress;
        address _initialOwner;
        uint[] _tierCeilings;
        uint[] _fees;
    }
    
    /**
     * ===================================================
     * ----------------- STATE VARIABLE ------------------
     * ===================================================
     */

    BondDetails[] public bondDetails;
    address public olympusProFactory;
    mapping(address => uint) public indexOfBond;

    /**
     * ===================================================
     * ----------------- EVENT ---------------------------
     * ===================================================
     */

    event BondCreation(address treasury, address bond, address staking, address _initialOwner);
    
    /**
     * ===================================================
     * ----------------- FUNCTIONS -----------------------
     * ===================================================
     */
    
    /**
        @notice pushes bond details to array, this array is used to track the bonds.
        @param _principalToken address
        @param _customTreasury address
        @param _customBond address
        @param _initialOwner address
        @param _tierCeilings uint[]
        @param _fees uint[]
        @return _treasury address
        @return _bond address
     */
    function pushBond(address _principalToken, address _customTreasury, address _customBond, address _stakingAddress, address _initialOwner, uint[] calldata _tierCeilings, uint[] calldata _fees) external returns(address _treasury, address _bond, address _stake) {
        require(olympusProFactory == msg.sender, "Not Olympus Pro Factory");

        indexOfBond[_customBond] = bondDetails.length;
        
        bondDetails.push( BondDetails({
            _principalToken: _principalToken,
            _treasuryAddress: _customTreasury,
            _bondAddress: _customBond,
            _stakingAddress: _stakingAddress,
            _initialOwner: _initialOwner,
            _tierCeilings: _tierCeilings,
            _fees: _fees
        }));

        emit BondCreation(_customTreasury, _customBond, _stakingAddress, _initialOwner);
        return( _customTreasury, _customBond, _stakingAddress );
    }

    /**
        @notice changes olympus pro factory address
        @param _factory address
     */
    function setFactoryAddress(address _factory) external onlyPolicy() {
        olympusProFactory = _factory;
    }
    
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

contract Ownable {

    address public policy;

    constructor () {
        policy = msg.sender;
    }

    modifier onlyPolicy() {
        require( policy == msg.sender, "Ownable: caller is not the owner" );
        _;
    }
    
    function transferManagment(address _newOwner) external onlyPolicy() {
        require( _newOwner != address(0) );
        policy = _newOwner;
    }
}