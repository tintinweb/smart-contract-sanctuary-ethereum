// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IRoilAuthority} from "./interfaces/IRoilAuthority.sol";
import {RoilAccessControlled} from "./types/RoilAccessControlled.sol";

contract RoilAuthority is IRoilAuthority, RoilAccessControlled {


    /* ========== STATE VARIABLES ========== */

    address public override governor;

    address public override server;

    address public override distributor;

    address public override treasury;

    address public newGovernor;

    address public newServer;

    address public newDistributor;

    address public newTreasury;


    /* ========== Constructor ========== */

    constructor(
        address _governor,
        address _server,
        address _distributor,
        address _treasury
    ) RoilAccessControlled( IRoilAuthority(address(this)) ) {
        governor = _governor;
        emit GovernorPushed(address(0), governor, true);
        server = _server;
        emit ServerPushed(address(0), server, true);
        distributor = _distributor;
        emit DistributorPushed(address(0), distributor, true);
        treasury = _treasury;
        emit TreasuryPushed(address(0), treasury, true);
    }


    /* ========== GOV ONLY ========== */

    function pushGovernor(address _newGovernor, bool _effectiveImmediately) external onlyGovernor {
        if( _effectiveImmediately ) governor = _newGovernor;
        newGovernor = _newGovernor;
        emit GovernorPushed(governor, newGovernor, _effectiveImmediately);
    }

    function pushServer(address _newServer, bool _effectiveImmediately) external onlyGovernor {
        if( _effectiveImmediately ) server = _newServer;
        newServer = _newServer;
        emit ServerPushed(server, newServer, _effectiveImmediately);
    }

    function pushDistributor(address _newDistributor, bool _effectiveImmediately) external onlyGovernor {
        if( _effectiveImmediately ) distributor = _newDistributor;
        newDistributor = _newDistributor;
        emit DistributorPushed(distributor, newDistributor, _effectiveImmediately);
    }

    function pushTreasury(address _newTreasury, bool _effectiveImmediately) external onlyGovernor {
        if( _effectiveImmediately ) treasury = _newTreasury;
        newTreasury = _newTreasury;
        emit TreasuryPushed(treasury, newTreasury, _effectiveImmediately);
    }


    /* ========== PENDING ROLE ONLY ========== */

    function pullGovernor() external {
        require(msg.sender == newGovernor, "!newGovernor");
        emit GovernorPulled(governor, newGovernor);
        governor = newGovernor;
    }

    function pullServer() external {
        require(msg.sender == newServer, "!newServer");
        emit ServerPulled(server, newServer);
        server = newServer;
    }

    function pullDistributor() external {
        require(msg.sender == newDistributor, "!newDistributor");
        emit DistributorPulled(distributor, newDistributor);
        distributor = newDistributor;
    }

    function pullTreasury() external {
        require(msg.sender == newTreasury, "!newTreasury");
        emit TreasuryPulled(treasury, newTreasury);
        treasury = newTreasury;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.10;

interface IRoilAuthority {
    /* ========== EVENTS ========== */
    
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event ServerPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event DistributorPushed(address indexed from, address indexed to, bool _effectiveImmediately);   
    event TreasuryPushed(address indexed from , address indexed to, bool _effectiveImmediately); 

    event GovernorPulled(address indexed from, address indexed to);
    event ServerPulled(address indexed from, address indexed to);
    event DistributorPulled(address indexed from, address indexed to);
    event TreasuryPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */
    
    function governor() external view returns (address);
    function server() external view returns (address);
    function distributor() external view returns (address);
    function treasury() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ITreasury {
    event Withdrawal(address indexed _user, uint256 amount);

    function royaltyTotal() external returns (uint256 royalties);
    function increaseBalance(uint32 _to, uint256 _amount, uint256 _royalty) external;
    function approveForTransfer(uint32 _userId, uint256 _amount) external;
    function royaltyWithdrawal(uint256 _amount) external;
    function userWithdrawal(address _userAddress, uint256 _amount) external;
    function updateUserAddress(uint32 _userId, address _newUserAddress) external;
    function getUserIdBalance(uint32 _userId) external returns (uint256 balance);
    function getUserAddressBalance(address _userAddress) external returns (uint256 balance);
    function getUserAddress(uint32 _userId) external returns (address userAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {IRoilAuthority} from "../interfaces/IRoilAuthority.sol";
import {ITreasury} from "../interfaces/ITreasury.sol";

abstract contract RoilAccessControlled {

    /// EVENTS ///
    event AuthorityUpdated(IRoilAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas
    string OVERDRAFT = "AMOUNT LARGER THAN BALANCE";
    
    /// STATE VARIABLES ///

    IRoilAuthority public authority;

    /// Constructor ///

    constructor(IRoilAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    

    /// MODIFIERS ///
    /// @notice only governor can call function
    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }
    
    /// @notice only server can call function
    modifier onlyServer() {
        require(msg.sender == authority.server(), UNAUTHORIZED);
        _;
    }

    /// @notice only distributor can call function
    modifier onlyDistributor() {
        require(msg.sender == authority.distributor(), UNAUTHORIZED);
        _;
    }

    /// @notice only treasury can call function
    modifier onlyTreasury() {
        require(msg.sender == authority.treasury(), UNAUTHORIZED);
        _;
    }

    /**
     * @notice checks to ensure any transfers from the treasury are available
                in the royaltyTotal tracker and updates variable following transfer
       @param _amount amount of withdrawal in ERC-20 transaction
     */
    modifier limitTreasuryActions(uint256 _amount) {
        if (msg.sender == authority.treasury() ) {
            ITreasury treasury = ITreasury(authority.treasury()); 
            require(
                treasury.royaltyTotal() >= _amount,
                OVERDRAFT
            );
            treasury.royaltyWithdrawal(_amount);
        }
        _;
    }

    /**
     * @notice limits the amount the treasury is allowed to approve to _spender balance
     * @param _spender address we are allocating allowance to
     * @param _amount total tokens to be allocated
     */
    modifier limitTreasuryApprovals(address _spender, uint256 _amount) {
        if (msg.sender == authority.treasury() ) {
            ITreasury treasury = ITreasury(msg.sender);
            require(treasury.getUserAddressBalance(_spender) >= _amount, OVERDRAFT);
        }
        _;
    }

    /**
     * @notice when ERC20 TransferFrom is called this modifier updates user balance
     *          in the treasury (needed for funds allocated via App without verified adress) 
     * @param from address we're transferring funds from
     * @param to end recipient of funds
     * @param amount total ROIL tokens to be transferred
     */
    modifier onTransferFrom(address from, address to, uint256 amount) {
        if (from == address(authority.treasury())) {
            ITreasury treasury = ITreasury(authority.treasury());
            
            // verify that the user has funds available in treasury contract
            require(treasury.getUserAddressBalance(to) >= amount, OVERDRAFT);
            treasury.userWithdrawal(to, amount);
        }
        _;
    }

    
    /// GOV ONLY ///
    
    /// @notice update authority contract only governor can call function
    function setAuthority(IRoilAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}