//SPDX-License-Identifier: MIT
pragma solidity *0.8.17;




contract Terra_Token
{
	uint256 public constant Width = 5;
	uint256 public constant Height = 5;
    uint256 public constant Total_Tiles = Width * Height;

    uint256[] public Tile_Target;
    int[] public Tile_Type;
    bool[] public Tile_Pathing;
    uint256[] public Tile_Contains; //What is currently in the square.

    constructor()
    {
        for (uint cou = 0; cou < Total_Tiles; cou++)
        {
            Tile_Target.push(0);
            Tile_Type.push(1);
            Tile_Pathing.push(true);
            Tile_Contains.push(0);
        }
    }


}




/*
TerraETHToken
{
    occupied_By = NULL
    metadata_URI
    pathing_Type //The unit has a movement type that is checked against this number
}

BioToken
{
    metadata_URI
    tile_Binding
}
*/