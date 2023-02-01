// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;  
//This staker contract will hold the main pool for staking-loan 
//and will be soon proxy contract tp hold other ...
import "../lib/Interest.sol";


contract Staker{
    //Using  DSMath and Interest packages for exponential interest calculation;
    uint256 Compound_interest;
    
    //addresses should be deployed contracts and client should interact via contract;
    mapping(address => uint256) public depositTimestamps;
    
    //If deployer requested escrow with staker ability;bool will be set true 
    mapping(address=>bool) public InterestSet;  
    
    //escrowTx is escrow transaction with contract-arbiter-beneficiary;
    mapping(address=>mapping(address=>address)) public escrowTx;
    
    //balances is Depositor balances inside staker contract;
    mapping(address=>uint) public balances;
    
    //contractBalances is balances for each contract inside staker pool;
    mapping(address=>uint) public contractBalances;
    uint256 public claimFor3Month = 12 weeks; 
    
    //uint256 public claimFor6Month = block.timestamp + 24 weeks; 
    mapping(address=>uint256) public interestValue;
    
    //Stake event fires up in ethStake function when depositor stake ether; 
    event Stake(address indexed sender, uint256 amount); 
    
    //Received event fires up in receive function;
    event Received(address, uint); 

    //withDrawal function send eth to beneficiary-send the interest eth amount to depositor; 
    function withDrawal(address _depositor,address _arbiter)external OnlyArbiter(msg.sender,_arbiter){
        require(contractBalances[msg.sender]>0,"Contract Balance is 0!");
       
        uint balance=contractBalances[msg.sender];
        //Choose 2 options regarding if the depositor requested 3 month interest payment while their escrow contract 
        //resting in the blockchain;--->Eth will be locked in the staker contract...
        //if no interest request it will just send the amount to beneficiary...
        if(InterestSet[_depositor]){
             //calculate the interest ---send the amount to beneficiary ---send the interest amount to depositor
             require(block.timestamp>=depositTimestamps[_depositor]+claimFor3Month,"Claim time not reached yet!");
             
             uint256 compoundBalance=CalculateInterest(_depositor);
             contractBalances[_depositor]=0;
            
            (bool success, )=payable(escrowTx[msg.sender][_arbiter]).call{value:balance}("");
            require(success,"Beneficiary base fee transaction failed!");
           
             uint interest_value=compoundBalance-balance;
             
             (bool success_2, )=payable(_depositor).call{value:interest_value}("");
              require(success_2,"Deployer interest transaction failed!"); 
           
           
        }else{
           
            contractBalances[_depositor]=0;
            (bool success, )=payable(escrowTx[msg.sender][_arbiter]).call{value:balance}("");
            require(success);
        }
    }
    
    function ethStake(address _depositor,address _arbiter,address _beneficiary,bool _isWithinterest)external payable returns(bool){
        require(msg.value>0,"You need to stake eth!");
         //deposit time recorded for future interest calculation;
         depositTimestamps[_depositor]=block.timestamp;
         //balances recorded for withdrawal;
         balances[_depositor]=msg.value;
         //escrow contract balances recored for withDrawal;
         contractBalances[msg.sender]=msg.value;
         //in the moment of withdrawal we will use this mapping to get the valid addreses to send the eth;
         setEscrowTxMapping(_arbiter,_beneficiary);
         //setting depositor true for interest gaining or false for no interest;
         setInterestMapping(_depositor,_isWithinterest);
         return true;
    }

    function CalculateInterest(address _depositor) public returns(uint256){
        Interest interestCalculator=new Interest();
        uint256 principal=balances[_depositor];
        
        uint256 rate=interestCalculator.yearlyRateToRay(0.3 ether);//0.3 ether roughly %30
        uint256 age=block.timestamp-depositTimestamps[_depositor];
         Compound_interest=interestCalculator.accrueInterest(principal,rate,age);
       
        interestValue[_depositor]=Compound_interest-principal;
        return Compound_interest;
    }
    
    

    //Setting interest map for staked eth...
    function setInterestMapping(address _address,bool _isWithinterest)internal {
        InterestSet[_address]=_isWithinterest;
     
    }
    
    //set the escrowTx mapping for arbiter and beneficiary
    function setEscrowTxMapping(address _arbiter,address _beneficiary)internal {
       escrowTx[msg.sender][_arbiter]=_beneficiary;
    }

    //verifies if the tx.origin is deployer--it may deprecate!
    modifier OnlyDeployer(address _address){
        require(depositTimestamps[_address]!=0,"You'r not the deployer!");
        _;
    }
    //verifies if the msg.sender is contract--- and signer is arbiter...
    modifier OnlyArbiter(address _address,address _arbiter){
        require(escrowTx[_address][_arbiter]!=address(0),"You'r not the arbiter!");
        _;
    }
    //Check address if it has interest order on;
    function checkInterestMapping()external view OnlyDeployer(msg.sender) returns(bool){
        //console.log("Balance:",balances[msg.sender]);
        return InterestSet[msg.sender];
    }
    //Check address for its deposit time;
    function checkdepositTimestamps(address _address)external view returns(uint256){
        return depositTimestamps[_address];
    }
    //Check address for interest amount so far;
    function checkInterestValue(address _depositor)public view returns(uint256){
        return interestValue[_depositor];
    }
     
     receive() external payable { 
        emit Received(msg.sender,msg.value);    
  }

}

// DSMath from DappHub -> https://github.com/dapphub/ds-math/blob/784079b72c4d782b022b3e893a7c5659aa35971a/src/math.sol

/// math.sol -- mixin for inline numerical wizardry

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;  

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;  

import "./DSMath.sol";

// Using DSMath from DappHub https://github.com/dapphub/ds-math
// More info on DSMath and fixed point arithmetic in Solidity:
// https://medium.com/dapphub/introducing-ds-math-an-innovative-safe-math-library-d58bc88313da

/**
* @title Interest
* @author Nick Ward
* @dev Uses DSMath's wad and ray math to implement (approximately)
* continuously compounding interest by calculating discretely compounded
* interest compounded every second.
*/
contract Interest is DSMath {

    //// Fixed point scale factors
    // wei -> the base unit
    // wad -> wei * 10 ** 18. 1 ether = 1 wad, so 0.5 ether can be used
    //      to represent a decimal wad of 0.5
    // ray -> wei * 10 ** 27

    // Go from wad (10**18) to ray (10**27)
    function wadToRay(uint _wad) internal pure returns (uint) {
        return mul(_wad, 10 ** 9);
    }

    // Go from wei to ray (10**27)
    function weiToRay(uint _wei) internal pure returns (uint) {
        return mul(_wei, 10 ** 27);
    } 


    /**
    * @dev Uses an approximation of continuously compounded interest 
    * (discretely compounded every second)
    * @param _principal The principal to calculate the interest on.
    *   Accepted in wei.
    * @param _rate The interest rate. Accepted as a ray representing 
    *   1 + the effective interest rate per second, compounded every 
    *   second. As an example:
    *   I want to accrue interest at a nominal rate (i) of 5.0% per year 
    *   compounded continuously. (Effective Annual Rate of 5.127%).
    *   This is approximately equal to 5.0% per year compounded every 
    *   second (to 8 decimal places, if max precision is essential, 
    *   calculate nominal interest per year compounded every second from 
    *   your desired effective annual rate). Effective Rate Per Second = 
    *   Nominal Rate Per Second compounded every second = Nominal Rate 
    *   Per Year compounded every second * conversion factor from years 
    *   to seconds
    *   Effective Rate Per Second = 0.05 / (365 days/yr * 86400 sec/day) = 1.5854895991882 * 10 ** -9
    *   The value we want to send this function is 
    *   1 * 10 ** 27 + Effective Rate Per Second * 10 ** 27
    *   = 1000000001585489599188229325
    *   This will return 5.1271096334354555 Dai on a 100 Dai principal 
    *   over the course of one year (31536000 seconds)
    * @param _age The time period over which to accrue interest. Accepted
    *   in seconds.
    * @return The new principal as a wad. Equal to original principal + 
    *   interest accrued
    */
    function accrueInterest(uint _principal, uint _rate, uint _age) external pure returns (uint) {
        return rmul(_principal, rpow(_rate, _age));
    }


    /**
    * @dev Takes in the desired nominal interest rate per year, compounded
    *   every second (this is approximately equal to nominal interest rate
    *   per year compounded continuously). Returns the ray value expected
    *   by the accrueInterest function 
    * @param _rateWad A wad of the desired nominal interest rate per year,
    *   compounded continuously. Converting from ether to wei will effectively
    *   convert from a decimal value to a wad. So 5% rate = 0.05
    *   should be input as yearlyRateToRay( 0.05 ether )
    * @return 1 * 10 ** 27 + Effective Interest Rate Per Second * 10 ** 27
    */
    function yearlyRateToRay(uint _rateWad) external pure returns (uint) {
        return add(wadToRay(1 ether), rdiv(wadToRay(_rateWad), weiToRay(365*86400)));
    }
}