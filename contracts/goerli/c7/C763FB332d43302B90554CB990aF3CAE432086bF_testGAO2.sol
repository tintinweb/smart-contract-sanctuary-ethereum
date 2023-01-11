pragma solidity >=0.8.0;    
     
contract testGAO2 {  
    uint256 public flag = 0;   
    function getAmountOutAssem1(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {   
        assembly {
            function getOut(amountIn0,reserveIn0,reserveOut0) -> amountOut0 {
                let amountInWithFee := mul(amountIn0 , 997)
                let numerator := mul(amountInWithFee , reserveOut0)
                let denominator := add(mul(reserveIn0 , 1000), amountInWithFee)
                amountOut0 := mload(div(numerator, denominator))
            }
            amountOut := getOut(amountIn,reserveIn,reserveOut)
        } 
    }

    function getAmountOutAssem2(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure returns (uint256 amountOut) {   
        assembly { 
            let amountInWithFee := mul(amountIn , 997)
            let numerator := mul(amountInWithFee , reserveOut)
            let denominator := add(mul(reserveIn , 1000), amountInWithFee)
            amountOut := mload(div(numerator, denominator))             
        } 
    }

    function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
    ) public pure returns (uint256 amountOut) {  
        uint256 amountInWithFee = amountIn * (997);
        uint256 numerator = amountInWithFee * (reserveOut);
        uint256 denominator = reserveIn * (1000) + (amountInWithFee);
        amountOut = numerator / denominator; 
    }

    function test(
    uint8 chooseAsse,
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
    ) public returns (uint256 amountOut) {         
        flag = 1; 
        if(chooseAsse==1) amountOut = getAmountOutAssem1(amountIn,reserveIn,reserveOut) ;
        else if(chooseAsse==2) amountOut = getAmountOutAssem2(amountIn,reserveIn,reserveOut) ;
        else amountOut = getAmountOut(amountIn,reserveIn,reserveOut) ;
        flag = 0;   
    }
}