//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ERC20} from "@rari-capital/solmate/src/tokens/ERC20.sol";
import {IRobos} from "./Interface/IRobos.sol";


contract ClankToken is ERC20("Clank Token", "CLANK", 18) {

/*/////////////////////////////////////////////////////////////
                      Public Vars
/////////////////////////////////////////////////////////////*/
    address public robosTeam;
    uint256 constant public LEGENDARY_RATE = 3 ether;
    uint256 constant public BASE_RATE = 2 ether;
    uint256 constant public JR_BASE_RATE = 1 ether;
    //INITAL_ISSUANCE off of mintint a ROBO
    uint256 constant public INITAL_ISSUANCE = 10 ether;
    /// End time for Base rate yeild token (UNIX timestamp)
    /// END time = Sun Jan 30 2033 01:01:01 GMT-0700 (Mountain Standard Time) - in 11 years
    uint256 constant public END = 2003835600;
    uint256 private constant TEAM_SUPPLY = 6_000_000 * 10**18;


/*/////////////////////////////////////////////////////////////
                        Mappings
/////////////////////////////////////////////////////////////*/
    
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public lastUpdate;

    IRobos public robosContract;

/*/////////////////////////////////////////////////////////////
                        Events
/////////////////////////////////////////////////////////////*/

    event RewardPaid(address indexed user, uint256 reward);

/*/////////////////////////////////////////////////////////////
                      Constructor
/////////////////////////////////////////////////////////////*/

    constructor(address _robos, address _robosTeam) {
        robosContract = IRobos(_robos);
        robosTeam = _robosTeam;
        _mint(robosTeam, TEAM_SUPPLY);
    }

/*/////////////////////////////////////////////////////////////
                  Modifier Functions
/////////////////////////////////////////////////////////////*/

    modifier onlyRobosContract() {
        require(
            msg.sender == address(robosContract),
            "Only Robos contract can call this."
        );
        _;
    }

/*/////////////////////////////////////////////////////////////
                    External Functions
/////////////////////////////////////////////////////////////*/

    function updateRewardOnMint(address _user, uint256 _amount) external onlyRobosContract() {
      uint256 time = min(block.timestamp, END);
      uint256 timerUser = lastUpdate[_user];
      if (timerUser > 0 ) {
          rewards[_user] = rewards[_user] + (robosContract.balanceOG(_user) * (BASE_RATE * (time - timerUser))) / 86400 + (_amount * INITAL_ISSUANCE);
      } else {
          rewards[_user] = rewards[_user] + (_amount * INITAL_ISSUANCE);
          lastUpdate[_user] = time;
      }
    }

    function updateReward(address _from, address _to, uint256 _tokenId) external onlyRobosContract() {
        //Lendary Rewards
        if (_tokenId < 16) {
            uint256 time = min(block.timestamp, END);
            uint256 timerFrom = lastUpdate[_from];

            if (timerFrom > 0) {
                rewards[_from] += robosContract.balanceOG(_from) * (LEGENDARY_RATE * (time - timerFrom)) / 86400; 
            }

            if (timerFrom != END) {
                lastUpdate[_from] = time;
            }
                        
            if (_to != address(0)) {
                uint256 timerTo = lastUpdate[_to];

                if (timerTo > 0) {
                    rewards[_to] += robosContract.balanceOG(_to) * (LEGENDARY_RATE * (time - timerTo)) / 86400;
                }

                if (timerTo != END) {
                    lastUpdate[_to] = time;
                }
            }
        }

        //Genesis Rewards
        if (_tokenId > 16 && _tokenId < 2223) {
            uint256 time = min(block.timestamp, END);
            uint256 timerFrom = lastUpdate[_from];

            if (timerFrom > 0) {
                rewards[_from] += robosContract.balanceOG(_from) * (BASE_RATE * (time - timerFrom)) / 86400;
            }

            if (timerFrom != END) {
                lastUpdate[_from] = time;
            } 

            if (_to != address(0)) {
                uint256 timerTo = lastUpdate[_to];

                if (timerTo > 0) {
                    rewards[_to] += robosContract.balanceOG(_to) * (BASE_RATE * (time - timerTo)) / 86400;
                }

                if (timerTo != END) {
                    lastUpdate[_to] = time;
                }
            }
        }
        // JR rewards
        if (_tokenId >= 2223) {
            uint256 time = min(block.timestamp, END);
            uint256 timerFrom = lastUpdate[_from];

            if (timerFrom > 0) {
                rewards[_from] += robosContract.jrCount(_from) * (JR_BASE_RATE * (time - timerFrom)) / 86400;
            }

            if (timerFrom != END) {
                lastUpdate[_from] = time;
            }

            if (_to != address(0)) {
                uint256 timerTo = lastUpdate[_to];

                if (timerTo > 0) {
                    rewards[_to] += robosContract.jrCount(_to) * (JR_BASE_RATE * (time - timerTo)) / 86400;
                }

                if (timerTo != END) {
                    lastUpdate[_to] = time;
                }
            }

        }
    }


    function getReward(address _to) external onlyRobosContract() {
      uint256 reward = rewards[_to];
      if (reward > 0) {
        rewards[_to] = 0;
        _mint(_to, reward);
        emit RewardPaid(_to, reward);
      }
    }

    function burn(address _from, uint256 _amount) external onlyRobosContract() {
      _burn(_from, _amount);
    }
     

    function getTotalClaimable(address _user) external view returns(uint256) {
        uint256 time = min(block.timestamp, END);
        uint256 pending = robosContract.balanceOG(_user) * (BASE_RATE * (time - lastUpdate[_user])) / 86400;
        uint256 legendaryPending = robosContract.balanceOG(_user) * (LEGENDARY_RATE * (time - lastUpdate[_user])) / 86400;
        uint256 jrPending = robosContract.jrCount(_user) * (JR_BASE_RATE * (time - lastUpdate[_user])) / 86400;
        return rewards[_user] + (pending + jrPending + legendaryPending);
    }
    
/*/////////////////////////////////////////////////////////////
                  Internal Functions
/////////////////////////////////////////////////////////////*/

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
      return a < b ? a : b;
    }
    
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                           EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRobos {
    function balanceOG(address _user) external view returns(uint256);

    function jrCount(address _user) external view returns(uint256);

    function generationOf(uint256 tokenId) external view returns (uint256 gene);

    function lastTokenId() external view returns (uint256 tokenId);

    function setMintCost(uint256 newMintCost) external;

    function setTxLimit(uint256 _bulkBuyLimit) external;

}