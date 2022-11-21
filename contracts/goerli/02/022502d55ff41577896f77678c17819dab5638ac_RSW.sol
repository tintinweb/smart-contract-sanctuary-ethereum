/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract RSW {
    enum Material {A, B, C, D, E, F, G}

    address owner;
    uint256 number;



    constructor()
    {
         owner = msg.sender;
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner, "not an owner");
        _;
    }




    function predict(uint current, 
                    uint time, 
                    RSW.Material m1, 
                    RSW.Material m2, 
                    uint weight1, 
                    uint weight2, 
                    uint thickness1, 
                    uint thickness2
                    ) public view  returns (int) 
    {
           if(current < 11550) return predict0(current, time, m1, m2, weight1, weight2, thickness1, thickness2);
           else return predict1(time);    
    }

    function predict0(uint current, 
                    uint time, 
                    RSW.Material m1, 
                    RSW.Material m2, 
                    uint weight1, 
                    uint weight2, 
                    uint thickness1, 
                    uint thickness2 
                    ) internal view  returns (int) 
    {  
            if(m1 == RSW.Material.B || m1 == RSW.Material.E || m1 == RSW.Material.F || m1 == RSW.Material.G)
                   return predict00(current, time, m1, m2, weight1, weight2, thickness1, thickness2);   
            else
                   return  predict01(current, time);

    }

 
    function predict1( 
                    uint time
                    ) internal view  returns (int) 
    {
        if(time < 275) return 6556;
        else return 7890;     
    }

   function predict00(uint current, 
                    uint time, 
                    RSW.Material m1, 
                    RSW.Material m2, 
                    uint weight1, 
                    uint weight2, 
                    uint thickness1, 
                    uint thickness2 
                    ) internal view  returns (int)
    {
        if(current < 10695) return predict000(current, time, m1, thickness1);   
        else return predict001(weight1);   
    } 

   function predict000(uint current, 
                    uint time, 
                    RSW.Material m1, 
                    uint thickness1 
                    ) internal view  returns (int)
    {
        if(m1 == RSW.Material.B || m1 == RSW.Material.G) return predict0000(time, thickness1);   
        else return 5434;   
    } 

   function predict001( 
                    uint weight1 
                    ) internal view  returns (int)
    {
          if(weight1 < 103500) return 5755;
          else return 8050;
    }

   function predict0000( 
                    uint time, 
                    uint thickness1 
                    ) internal view  returns (int)
    {
        if(thickness1 < 900) return predict00000(time);
        else return 4970;
        
    }

  function predict00000( 
                    uint time
                     ) internal view  returns (int)
 
    {
        if(time < 310) return 2907;
        else return 5267;
    
    }

 function predict01(uint current, 
                    uint weight2
                    ) internal view  returns (int)
    {
        if(current < 8450) return 6012;
        else return predict001(current, weight2); 
    }
 
   function predict001(uint current, 
                    uint weight2
                    ) internal view  returns (int)
    {
        if(weight2 < 25000) return 7991;
        else return predict0011(current); 
    }

   function predict0011(uint current
                    ) internal view  returns (int)
    {
        if(current < 9900) return 6138;
        else return 7663; 
    }
}