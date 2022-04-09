// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./IVIP.sol";

contract LatinVIP is VIP {

mapping(address => bool)  Owner;
mapping(address => bool)  Staff;

uint32 public Block_bsc;
uint32 public Block_bsc_ts;

address[] public holders;
uint256 public n_holders;
mapping(address => uint256 ) public balance;
mapping(address => bool ) public registrado;

event Balance_VIP( uint32 Block_bsc , uint32 Block_bsc_ts);

    constructor() { 
        Owner[msg.sender] = true ;
}

 function get_bal(address account) external view returns (uint256)
 {return balance[account];}

function get_blck_bsc() external view returns (uint32)
{return Block_bsc;}

function get_blck_bsc_ts() external view returns (uint32)
{return Block_bsc_ts;}

function get_holder(uint32 n) external view returns (address)
{return holders[n];}

function get_n_holders() external view returns (uint256)
{return holders.length;}

    function set_rol(bool  _tm, address  _addr, uint  _rol) external {
        require((_rol >= 1 && _rol <=3 && Owner[msg.sender] ) || (_rol ==3 && Staff[msg.sender]),"No autorizado");

            if (_rol == 1) Owner[_addr] = _tm;
            if (_rol == 2) Staff[_addr] = _tm;
        }


    function Pub_Balance(uint32  _blk_num,  uint32 _bl_ts) public {
        require( Staff[msg.sender] , "no autorizado");
        Block_bsc = _blk_num;
        Block_bsc_ts = _bl_ts;
        n_holders = holders.length;
         emit  Balance_VIP(Block_bsc, Block_bsc_ts);

        }

   function Sync_Balance (address _holder, uint256 _bal) public {
        require(_holder != address(0), "PaymentSplitter: account is the zero address");
        require( Staff[msg.sender] , "no autorizado");
  
            if (!registrado[_holder]) 
            {registrado[_holder] = true ; 
                holders.push(_holder);
            }
          balance[_holder]=_bal;
        }
    


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface VIP  {

function get_bal(address account) external view returns (uint256);
function get_blck_bsc() external view returns (uint32);
function get_blck_bsc_ts() external view returns (uint32);
function get_holder(uint32 n) external view returns (address);
function get_n_holders() external view returns (uint256);

}