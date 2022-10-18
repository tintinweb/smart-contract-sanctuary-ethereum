// SPDX-License-Identifier: MIT
    pragma solidity^0.8.0;

    import './_voting.sol';

    contract daoDeployer {

        
        struct Dao{

            string daoName;
            myDao daoNew;
            address creator;
        }

        Dao[] daos;


        function createDao(string memory _name) public {

            myDao newDao = new myDao();
            daos.push(Dao({
                daoName : _name,
                daoNew : newDao,
                creator : msg.sender
            }));

        }

        function viewDao() public view returns(uint,myDao) {
            uint id;
            myDao daoAddress;
            for(uint i=0;i<daos.length;i++){
                if(daos[i].creator==msg.sender){
                    id = i;
                    daoAddress = daos[i].daoNew;
                }
            }
            return (id,daoAddress);
        }

    }