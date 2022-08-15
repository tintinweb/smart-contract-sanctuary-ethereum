/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// File: dumper_shiled_smart_contract/DumperShieldToken.sol



pragma solidity ^0.8.0;



interface IERC20 {

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

}



interface IDSFactory {

    function totalSupply(address token) external view returns (uint256);

    function getLock(address token, address user) external view returns(uint256);

    function setLock(address token, address user, uint256 time) external returns(bool);

}



contract DumperShieldUser {



    address public factory; // dumper shield factory

    address public user;

/*

    address public dumperShield;

    modifier onlyDumperShield() {

        require(dumperShield == msg.sender, "Only dumperShield allowed");

        _;

    }

*/

    modifier onlyFactory() {

        require(factory == msg.sender, "onlyFactory");

        _;

    }



    constructor (address _user, address _factory) {

        require(_user != address(0) && _factory != address(0));

        user = _user;

        factory = _factory;

    }



    function safeTransfer(address token, address to, uint value) external onlyFactory {

        // bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'DumperShieldUser: TRANSFER_FAILED');

    }

}



contract DumperShieldToken {

    IERC20 public shieldedToken;   // address of shielded token

    address public factory; // dumper shield factory

    //address public router;

    mapping(address => address) public dumperShieldUsers;   // user address => DumperShieldUser contract

    address public DAO; // address of global voting contract



    event CreateDumperShieldUser(address user, address dsUserContract);



    modifier onlyFactory() {

        require(factory == msg.sender, "onlyFactory");

        _;

    }



    function initialize(address _token, address _dao) external {

        require(address(shieldedToken) == address(0) && _token != address(0));

        shieldedToken = IERC20(_token);

        DAO = _dao;

        //router = _router;

        factory = msg.sender;

    }

    /**

     * @dev Gets the balance of the specified address.

     * @param user The address to query the the balance of.

     * @return balance an uint256 representing the amount owned by the passed address.

     */

    function balanceOf(address user) external view returns (uint256 balance) {

        return shieldedToken.balanceOf(dumperShieldUsers[user]);

    }



    // returns DumperShieldUser contract address. If user has not contract - create it.

    function createDumperShieldUser(address user, address dsUser) external onlyFactory returns(address) {



        if (dsUser == address(0)) {

            dsUser = address(new DumperShieldUser(user, factory));

            emit CreateDumperShieldUser(user, dsUser);

        } else if (dumperShieldUsers[user] == dsUser) {

            return dsUser;

        }

        dumperShieldUsers[user] = dsUser;

        return dsUser;

    }



    function totalSupply() external view returns (uint256) {

        return IDSFactory(factory).totalSupply(address(shieldedToken));

    }



    function setLock(address user, uint256 time) external returns(bool) {

        require(msg.sender == DAO, "Only DAO");

        return IDSFactory(factory).setLock(address(shieldedToken), user, time);

    }



    function getLock(address user) external view returns(uint256) {

        return IDSFactory(factory).getLock(address(shieldedToken),user);

    }



    function setDAO(address _dao) external returns (bool) {

        require(msg.sender == factory, "Only factory");

        DAO = _dao;

        return true;

    }



    // allow to rescue tokens that were transferet to this contract by mistake

    function safeTransfer(address token, address to, uint value) external onlyFactory {

        // bytes4(keccak256(bytes('transfer(address,uint256)')));

        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));

        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');

    }

}