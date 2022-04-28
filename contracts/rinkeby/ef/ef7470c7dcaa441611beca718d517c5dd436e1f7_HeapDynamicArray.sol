/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

pragma solidity >=0.4.22;
pragma experimental ABIEncoderV2;

//Heap with dynamic array wrapped in a priority queue
contract HeapDynamicArray{
  

/**
*   @dev 
    Orderstruct with its elements:
        Sender: The address of the trader submitting the order
        Price: The price of the order
        Volume: The volume of the order
        AuxPrice: The contcantenation of the order's price and the counter which helps to sort the heap when there are ties
    
    buyList: The array that contains bid OrderStructs, it is a maxheap (decrementally sorted)
    sellList: The array that contains ask OrderStructs, it is a minheap (incrementally sorted)
*/
    struct OrderStruct 
    {
        address Sender;
        uint256 Price;
        uint256 Volume;     
        uint256 AuxPrice;   

    }

    OrderStruct[] internal buyList;  
    OrderStruct[] internal sellList; 

//*****************************************************************//
//**********************  buyList Functions  **********************//
//*****************************************************************//

//***********************************************************************//

    /**
    *   @dev Adds the incoming bid orders to the end of the buyList array which will be then heapified
    */
  
    function insertBid (address sender, uint256 price, uint256 volume, uint256 auxprice) public 
    {
        OrderStruct memory neworder = OrderStruct(sender, price , volume, auxprice);
        buyList.push(neworder);
        maxheapHeapifyUp();
    }    
//***********************************************************************//

    /**
    *   @dev Sorts the heap
    */
    
    function maxheapHeapifyUp () internal returns (bool) {
        
        //k is set to be the index of the last entry of the buyList array which is the oredr that has been added and needs to be moved up
        uint256 k = buyList.length - 1;                   

        //while we havent reached to the top of the heap
        while (k > 0){       
            //compute the parent of this last element which is p = (k-1)/2                           
            uint256 p = (k-1)/2;  
            //if the element's price is greater than its parent's price                         
            if (buyList[k].AuxPrice > buyList[p].AuxPrice) 
            {   
                //swap the element at index k with its parent
                OrderStruct memory temp = buyList[k];    
                buyList[k] = buyList[p];
                buyList[p] = temp;
                //k moves up one level
                k = p;                                  
            }
            //if not, break statement exits the loop (it continues until no element index k is greater than its parent)
            else {break;}                               
        }
        return true;
    }

//***********************************************************************//

    /**
    *   @dev Removes and returns the highest priority element of the buyList
        Only if the buyList is not empty
        then the heap is reordered using the heapifyDown method
    */

    function buyListMaxDelete() external returns (uint256, address, uint256) 
    {
        require (buyList.length != 0,'buyList is empty!');
        
        //If the buyList has only one order
        if (buyList.length == 1) {                                                          
            uint256 _price =  buyList[0].Price;
            address _sender =  buyList[0].Sender;
            uint256 _volume = buyList[0].Volume;
            buyList.pop();                                                  
            return (_price ,_sender, _volume);     
       
        }

        uint256 _price =  buyList[0].Price;
        address _sender =  buyList[0].Sender;
        uint256 _volume = buyList[0].Volume;
        //The last elementof the buyList is removed and written into the first position
        buyList[0] = buyList[buyList.length -1]; 
        buyList.pop();
        maxheapHeapifyDown();
        return (_price, _sender, _volume);  
    }
//***********************************************************************//
    /**
    *   @dev Returns the sender, price, and volume of the highest priority element (The highest bid)
    */ 
    function buyListMax() external view returns (uint256, address, uint256){
        
        require (buyList.length != 0,'buyList is empty!');  //throws exception if the buylist is empty
        return (buyList[0].Price, buyList[0].Sender, buyList[0].Volume);
        
    }

//***********************************************************************//

    /**
    *   @dev Heapifydown the buyList when a bid order is removed 
    */ 

    function maxheapHeapifyDown () internal returns (bool)
    {
        uint256 k =0;
        uint256 leftchild = 2*k + 1;
        
        //As long as the left child is within the array that heap is stored in
        while (leftchild < buyList.length)
        {                                   
            uint256 max = leftchild;
            //rightchild = 2k+2
            uint256 rightchild = leftchild + 1;                                     
            //if there is a rightchild
            if (rightchild < buyList.length)                                       
            {   
                //then the right child and left child are compared
                if (buyList[rightchild].AuxPrice > buyList[leftchild].AuxPrice)    
                {
                    //now max is set to rightchild, otherwise max remains to be the leftchild
                    max++;                                                       
                }
            }
            //compares the k item with the max item and if k is smaller than its greatest children they are swapped
            if (buyList[k].AuxPrice < buyList[max].AuxPrice)                        
            {
            
                OrderStruct memory temp = buyList[k];
                buyList[k] = buyList[max];    
                buyList[max] = temp;
                //k is set to max
                k = max;    
                //leftchild is recompuetd in preparation for the next iteration                                                     
                leftchild =2*k + 1;                                              
            }
            else
            { 
                //if the k item is not smaller than the max item, heapifyDown should stop                                                              
                break;
            }
        }
        return true;
    }

//***********************************************************************//
    /**
    *   @dev Checks if the buyList is empty or not
    */ 
    function buyListisEmpty() external view returns (bool){
        
        if (buyList.length == 0) 
        {
            return true;

        }
        else
        {
            return false;
        }
        
    }
//*****************************************************************//
//**********************  SellList Functions  *********************//
//*****************************************************************//

//***********************************************************************//

    /**
    *   @dev Adds the incoming ask orders to the end of the sellList array which will be then heapified
    */

    function insertAsk (address sender, uint256 price, uint256 volume, uint256 auxprice) public  
    {
        OrderStruct memory neworder = OrderStruct(sender, price , volume, auxprice); 
        sellList.push(neworder);
        minheapHeapifyUp();
        
    }    

    function loopCodeForAsk (address sender, uint256 price, uint256 volume, uint256 auxprice) public  
    {
        for (uint256 i =0; i< 100; i++)
        {
            insertAsk(sender, price+1, volume, ((i%2==0)?auxprice+i: auxprice-i));
//            buyListisEmpty();
        }
    }
    
    function loopCodeForBid (address sender, uint256 price, uint256 volume, uint256 auxprice) public  
    {
        for (uint256 i =0; i< 100; i++)
        {
            insertBid(sender, price+1, volume, auxprice-i);
//            buyListisEmpty();
        }
    }
    

    

//***********************************************************************//

    /**
    *   @dev Sorts the heap
    */
    function minheapHeapifyUp () internal returns (bool) {

        //k is set to be the index of the last entry of the sellList array which is the oredr that has been added and needs to be moved up
        uint256 k = sellList.length - 1; 
        //while we havent reached to the top of the heap
        while (k > 0){                                      
            //we need to compute the parent of this last element which is p = (k-1)/2
            uint256 p = (k-1)/2;                            
            //if the element is smaller than its parent
            if (sellList[k].AuxPrice < sellList[p].AuxPrice) 
            { 
                //swap the element at index k with its parent
                OrderStruct memory temp = sellList[k];    
                sellList[k] = sellList[p];
                sellList[p] = temp;
                //k moves up one level
                k = p; 
            }
            //if not, the break statement exits the loop (it continues until no element index k is smaller than its parent)
            else {break;} 
        }
        
        return true;
    }    
//***********************************************************************//

    /**
    *   @dev Removes and returns the highest priority element of the sellList (the lowest ask order)
        Only if the sellList is not empty
        then the heap is reordered using the heapifyDown method
    */
    function sellListMaxDelete() external returns (uint256, address, uint256)
    
    {
        require(sellList.length != 0, 'sellList is empty!');             
        //if the heap has only one order
        if (sellList.length == 1) {                               
            uint256 _price =  sellList[0].Price;
            address _sender =  sellList[0].Sender;
            uint256 _volume = sellList[0].Volume;
            sellList.pop();                                    
            return (_price, _sender, _volume);
        }

        uint256 _price =  sellList[0].Price;
        address _sender =  sellList[0].Sender;
        uint256 _volume = sellList[0].Volume;
        //the last elementof the heap is removed and written into the first position
        sellList[0] = sellList[sellList.length -1];                      
        sellList.pop(); 
        minheapHeapifyDown();                           
        return (_price, _sender, _volume);       
    }
//***********************************************************************//
    /**
    *   @dev Returns the sender, price, and volume of the highest priority element (The lowest ask)
    */ 
    function sellListMax() external view returns (uint256, address, uint256){
        
        require(sellList.length != 0, 'sellList is empty!');  //throws exception if the sellist is empty
        return (sellList[0].Price, sellList[0].Sender, sellList[0].Volume);
        
    }

//***********************************************************************//

    /**
    *   @dev Heapifydown the sellList when an order is removed 
    */ 

    function minheapHeapifyDown () internal returns (bool) 
    {
        uint256 k =0;
        uint256 leftchild = 2*k + 1;
        //as long as the left child is within the array that heap is stored in
        while (leftchild < sellList.length){               
            uint256 min = leftchild;
            //rightchild = 2k+2
            uint256 rightchild = leftchild + 1;              
            
            //if there is a rightchild, then the right child and left child are compared
            if (rightchild < sellList.length)               
            {
                if (sellList[rightchild].AuxPrice < sellList[leftchild].AuxPrice)
                {   //now min is set to rightchild, otherwise min remains to be the leftchild
                    min++;   
                }                               
            }
            //compares the k item with the max item and if its less they are swapped
            if (sellList[min].AuxPrice < sellList[k].AuxPrice) 
            {                   
                //swap the element at index k with its parent 
                OrderStruct memory temp = sellList[k];    
                sellList[k] = sellList[min];
                sellList[min] = temp;
                
                //k is set to min
                k = min; 
                //leftchild is recompuetd in preparation for the next iteration
                leftchild = 2*k + 1; 
            }
            //if k item's smaller childer is not smaller than k item itself, heapifyDown should stop
            else
            { 
                break;
            }

        }
        return true;
    }

//***********************************************************************//
    /**
    *   @dev Checks if the sellList is empty or not
    */

    function sellListisEmpty() external view returns (bool){
        
        if (sellList.length == 0) 
        {
            return true;

        }
        else
        {
            return false;
        }
        
    }
        






}