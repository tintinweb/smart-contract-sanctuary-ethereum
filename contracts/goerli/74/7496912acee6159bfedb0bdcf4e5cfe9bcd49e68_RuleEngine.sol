/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;



error NodeExistError(uint);
error NodeNotExistError(uint);


contract RuleEngine{
 
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

    enum Parameter {current, time, m1, m2, weight1, weight2, thickness1, thickness2}
    struct Argument{
        uint current;
        uint time;
        uint m1;
        uint m2; 
        uint weight1; 
        uint weight2; 
        uint thickness1;
        uint thickness2;
    }

    struct NodeInfo{   
        RuleEngine.Parameter parameter;
        uint threshold; // smaller or no less than
        uint[] catValues;  // equal to one of these values
        uint left;
        uint right;
        bool isCategorical;  // true: categorical; false: numerical
        bool isLeftLeaf;
        bool isRightLeaf;
    }


    mapping (uint => bool) nodeExists;

    // each node has a left node
    mapping(uint => NodeInfo) nodeTable;



 

    function insertNode(uint nodeid, 
                        RuleEngine.Parameter parameter, 
                        uint threshold, 
                        uint left,
                        uint right,
                        bool isCategorical, 
                        bool isLeftLeaf, 
                        bool isRightLeaf
                        ) 
                        public returns(bool){
           if(nodeExists[nodeid]) revert NodeExistError(nodeid);

        nodeExists[nodeid] = true;
        uint[] memory empty;
        nodeTable[nodeid] = NodeInfo(parameter, 
                                    threshold, 
                                    empty,
                                    left, 
                                    right, 
                                    isCategorical,
                                    isLeftLeaf,
                                    isRightLeaf
                            );
        return true;
    }   

    function insertCatvalue(uint nodeid, uint v) public {
        if(!nodeExists[nodeid]) revert NodeNotExistError(nodeid);
        uint[] storage cat = nodeTable[nodeid].catValues;
        cat.push(v);       
    }


    function deleteNode(uint nodeid) 
                        onlyOwner external returns(bool){
           if(!nodeExists[nodeid]) revert NodeNotExistError(nodeid);
        delete nodeTable[nodeid];
        delete nodeExists[nodeid];

        return true;
    }   




    function getValue(Argument memory env, RuleEngine.Parameter p) private pure returns (uint){
        if(p == RuleEngine.Parameter.current) return env.current;
        else if(p == RuleEngine.Parameter.time) return env.time;
        else if(p == RuleEngine.Parameter.m1) return env.m1;
        else if(p == RuleEngine.Parameter.m2) return env.m2;
        else if(p == RuleEngine.Parameter.weight1) return env.weight1;
        else if(p == RuleEngine.Parameter.weight2) return env.weight2;
        else if(p == RuleEngine.Parameter.thickness1) return env.thickness1;
        else if(p == RuleEngine.Parameter.thickness2) return env.thickness2;
        else return 0;
    }

    function isEqCategorical(uint v, uint[] memory values) pure internal returns(bool){
         uint len = values.length;

         for(uint i; i<len; ){
             if(v == values[i]) return true;
             unchecked{++i;}
         }

         return false;
    }



    function predict(uint current, 
                    uint time, 
                    uint m1, 
                    uint m2, 
                    uint weight1, 
                    uint weight2, 
                    uint thickness1, 
                    uint thickness2
                    ) external view returns (uint) 
    {

           Argument memory  env = Argument(current, time, m1, m2, weight1, weight2, thickness1, thickness2);    
    
           return eval(1, env); // evaluate the root node
    }

    

    function eval(uint nodeid, Argument memory env) view internal returns (uint){
       NodeInfo storage n = nodeTable[nodeid];
       RuleEngine.Parameter parameter = n.parameter;
       uint parameterValue = getValue(env, parameter);
       uint[] memory values = n.catValues;

        if(n.isCategorical){ // it is a categorical value
            if(isEqCategorical(parameterValue, values)) 
                 return n.isLeftLeaf? n.left: eval(n.left, env);
            else return n.isRightLeaf? n.right: eval(n.right, env);
        }           
        else{ // it is a numerical value
            if(parameterValue < n.threshold) return n.isLeftLeaf? n.left: eval(n.left, env);
            else return n.isRightLeaf? n.right: eval(n.right, env);
        }
      
    }



    function insertTree() external{
         insertNode(1, RuleEngine.Parameter.current, 11550, 2, 3, false, false, false);
         insertNode(2, RuleEngine.Parameter.m1, 0, 4, 5, true, false, false);
         insertCatvalue(2, 1);
         insertCatvalue(2, 4);
         insertCatvalue(2, 5);
         insertCatvalue(2, 6);
         insertNode(3, RuleEngine.Parameter.time, 275, 6556, 7890, false, true, true);
         insertNode(4, RuleEngine.Parameter.current, 10695, 6, 7, false, false, false);
         insertNode(5, RuleEngine.Parameter.current, 8450, 6012, 8, false, true, false);
         insertNode(6, RuleEngine.Parameter.m1, 0, 9, 5434, true, false, true);
         insertCatvalue(6, 1);
         insertCatvalue(6, 6);
         insertNode(7, RuleEngine.Parameter.weight1, 103500, 5755, 8050, false, true, true);
         insertNode(8, RuleEngine.Parameter.weight2, 25000, 7991, 11, false, true, false);
         insertNode(9, RuleEngine.Parameter.thickness1, 900, 10, 4970, false, false, true);
         insertNode(10, RuleEngine.Parameter.time, 310, 2907, 5267, false, true, true);
         insertNode(11, RuleEngine.Parameter.current, 9900, 6138, 7663, false, true, true);
    }
}