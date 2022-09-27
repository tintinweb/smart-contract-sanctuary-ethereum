/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

contract TEMO{
    enum Order{Buy, Sell}
    enum LEMstatus{Cleared, Penalized, Uncleared}
    address private DSO;

    event LEMstart(uint256 stime, uint256 etime);
    event LEMend(uint256 MCP, uint256 MCQ, uint256 etime);

    struct TEF{ 
    address owner; 
    uint256 amount; 
    uint256 price; 
    Order agent; 
    uint256 bidtime;
    }

    struct TEFtslot{ 
    TEF[] Demand;
    TEF[] Supply;
    }


    TEF[] public DemandBids;
    TEF[] public SupplyBids;
    TEFtslot[24] Marketdata;

    uint endLEM;
    uint256 MCP;
    uint256 MCQ;
    uint256 Rprice = 150;
    uint256 RestrictedDemand = 1000;
    LEMstatus LEMcleared = LEMstatus.Uncleared;

    modifier OnlyDSO(){
        require(msg.sender == DSO, "Caller is not DSO");
        _;
    }

    function sortA(TEF[] memory data) public returns(TEF[] memory) {
        quickSortA(data, int(0), int(data.length - 1));
        return data;
    }

    function sortD(TEF[] memory data) public returns(TEF[] memory)  {
        quickSortD(data, int(0), int(data.length - 1));
        return data;
    }
    
    function quickSortA(TEF[] memory arr, int left, int right) internal{
        int i = left;
        int j = right;
        if(i==j) return;
        TEF memory pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)].price < pivot.price) i++;
            while (pivot.price < arr[uint(j)].price) j--;
            if (i <= j) {
                TEF memory swap = arr[uint(i)];
                arr[uint(i)] = arr[uint(j)];
                arr[uint(j)] = swap;
                //(arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortA(arr, left, j);
        if (i < right)
            quickSortA(arr, i, right);
    }

    function quickSortD(TEF[] memory arr, int left, int right) internal{
        int i = left;
        int j = right;
        if(i==j) return;
        TEF memory pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)].price > pivot.price) i++;
            while (pivot.price > arr[uint(j)].price) j--;
            if (i <= j) {
                TEF memory swap = arr[uint(i)];
                arr[uint(i)] = arr[uint(j)];
                arr[uint(j)] = swap;
                //(arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortD(arr, left, j);
        if (i < right)
            quickSortD(arr, i, right);
    }

    function startLEM() public { 
        //if(msg.sender != DSO) revert(); 
            uint t = 30 minutes; 
            endLEM = t + block.timestamp;
            emit LEMstart(block.timestamp,endLEM); 
    }
    
    function Bid(uint256[24] memory _amount, int256[24] memory _price) public{
        //require(_amount > 0, "Amount must not be zero");
        //require(_price > 0, "Price must not be zero");
        if (block.timestamp > endLEM) revert();
        for(uint i = 0; i <= 23; i++){
            if(_price[i] > 0){
                //SupplyBids.push() = TEF(msg.sender, _amount[i], uint256(_price[i]), Order.Sell, block.timestamp);
                Marketdata[i].Supply.push() = TEF(msg.sender, _amount[i], uint256(_price[i]), Order.Sell, block.timestamp);       
            } 
            else{
                //DemandBids.push() = TEF(msg.sender, _amount[i], uint256(abs(_price[i])), Order.Buy, block.timestamp);
                Marketdata[i].Demand.push() = TEF(msg.sender, _amount[i], uint256(abs(_price[i])), Order.Buy, block.timestamp);
            }
        }
        
    }

    function closeLEM() public{ 
        //if(msg.sender != DSO) revert(); 
            endLEM = block.timestamp; 
            TEFtslot[24] memory Marketdata_s = Marketdata;
            
            for(uint i = 0; i <= 23; i++){
                if(Marketdata[i].Supply.length > 0)
                    Marketdata_s[i].Supply = sortA(Marketdata[i].Supply);
                if(Marketdata[i].Demand.length > 0)
                    Marketdata_s[i].Demand = sortD(Marketdata[i].Demand);
            }
            
            // for(uint i = 0; i <= 23; i++){
            //     if(Marketdata[i].Supply.length > 0){
            //         for(uint j = 0; j < (Marketdata[i].Supply.length); j++){
            //             Marketdata[i].Supply[j] = Marketdata_s[i].Supply[j];     
            //         }
            //     }
            //     // if(Marketdata[i].Demand.length > 0){
            //     //     for(uint j = 0; j <= (Marketdata[i].Supply.length - 1); j++){
            //     //       Marketdata[i].Demand[j] = Marketdata_s[i].Demand[j];
            //     //     }
            //     // }
            // }
                
    }


    function getSupplyBids()  public view returns(TEF[] memory){
        // TEF[] memory _temp;
        // for(uint i = 0; i < 24; i++){
        //     if(Marketdata[i].Supply.length > 0){
        //             for(uint j = 0; j <= (Marketdata[i].Supply.length - 1); j++){
        //                 _temp.push() = Marketdata[i].Supply;
        //             }
        //         }
            
        // }
        return Marketdata[0].Supply;
    }

    
    function getLastMCP()  public view returns(uint256){
        return MCP;
    }

    function getLastMCQ()  public view returns(uint256){
        return MCQ;
    }

    function getRetailPrice()  public view returns(uint256){
        return Rprice;
    }

    function getLastLEMstatus()  public view returns(LEMstatus){
        return LEMcleared;
    }

    function abs(int256 x) private pure returns (int256) {
    return x >= 0 ? x : -x;
}
    

}