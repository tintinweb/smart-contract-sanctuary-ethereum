// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ShackledStructs.sol";
import "./ShackledMath.sol";
import "./Trigonometry.sol";

/* 
dir codes:
    0: right-left
    1: left-right
    2: up-down
    3: down-up

 sel codes:
    0: random
    1: biggest-first
    2: smallest-first
*/

library ShackledGenesis {
    uint256 constant MAX_N_ATTEMPTS = 150; // max number of attempts to find a valid triangle
    int256 constant ROT_XY_MAX = 12; // max amount of rotation in xy plane
    int256 constant MAX_CANVAS_SIZE = 32000; // max size of canvas

    /// a struct to hold vars in makeFacesVertsCols() to prevent StackTooDeep
    struct FacesVertsCols {
        uint256[3][] faces;
        int256[3][] verts;
        int256[3][] cols;
        uint256 nextColIdx;
        uint256 nextVertIdx;
        uint256 nextFaceIdx;
    }

    /** @dev generate all parameters required for the shackled renderer from a seed hash
    @param tokenHash a hash of the tokenId to be used in 'random' number generation
    */
    function generateGenesisPiece(bytes32 tokenHash)
        external
        view
        returns (
            ShackledStructs.RenderParams memory renderParams,
            ShackledStructs.Metadata memory metadata
        )
    {
        /// initial model paramaters
        renderParams.objScale = 1;
        renderParams.objPosition = [int256(0), 0, -2500];

        /// generate the geometry and colors
        (
            FacesVertsCols memory vars,
            ColorUtils.ColScheme memory colScheme,
            GeomUtils.GeomSpec memory geomSpec,
            GeomUtils.GeomVars memory geomVars
        ) = generateGeometryAndColors(tokenHash, renderParams.objPosition);

        renderParams.faces = vars.faces;
        renderParams.verts = vars.verts;
        renderParams.cols = vars.cols;

        /// use a perspective camera
        renderParams.perspCamera = true;

        if (geomSpec.id == 3) {
            renderParams.wireframe = false;
            renderParams.backfaceCulling = true;
        } else {
            /// determine wireframe trait (5% chance)
            if (GeomUtils.randN(tokenHash, "wireframe", 1, 100) > 95) {
                renderParams.wireframe = true;
                renderParams.backfaceCulling = false;
            } else {
                renderParams.wireframe = false;
                renderParams.backfaceCulling = true;
            }
        }

        if (
            colScheme.id == 2 ||
            colScheme.id == 3 ||
            colScheme.id == 7 ||
            colScheme.id == 8
        ) {
            renderParams.invert = false;
        } else {
            /// inversion (40% chance)
            renderParams.invert =
                GeomUtils.randN(tokenHash, "invert", 1, 10) > 6;
        }

        /// background colors
        renderParams.backgroundColor = [
            colScheme.bgColTop,
            colScheme.bgColBottom
        ];

        /// lighting parameters
        renderParams.lightingParams = ShackledStructs.LightingParams({
            applyLighting: true,
            lightAmbiPower: 0,
            lightDiffPower: 2000,
            lightSpecPower: 3000,
            inverseShininess: 10,
            lightColSpec: colScheme.lightCol,
            lightColDiff: colScheme.lightCol,
            lightColAmbi: colScheme.lightCol,
            lightPos: [int256(-50), 0, 0]
        });

        /// create the metadata
        metadata.colorScheme = colScheme.name;
        metadata.geomSpec = geomSpec.name;
        metadata.nPrisms = geomVars.nPrisms;

        if (geomSpec.isSymmetricX) {
            if (geomSpec.isSymmetricY) {
                metadata.pseudoSymmetry = "Diagonal";
            } else {
                metadata.pseudoSymmetry = "Horizontal";
            }
        } else if (geomSpec.isSymmetricY) {
            metadata.pseudoSymmetry = "Vertical";
        } else {
            metadata.pseudoSymmetry = "Scattered";
        }

        if (renderParams.wireframe) {
            metadata.wireframe = "Enabled";
        } else {
            metadata.wireframe = "Disabled";
        }

        if (renderParams.invert) {
            metadata.inversion = "Enabled";
        } else {
            metadata.inversion = "Disabled";
        }
    }

    /** @dev run a generative algorithm to create 3d geometries (prisms) and colors to render with Shackled
    also returns the faces and verts, which can be used to build a .obj file for in-browser rendering
     */
    function generateGeometryAndColors(
        bytes32 tokenHash,
        int256[3] memory objPosition
    )
        internal
        view
        returns (
            FacesVertsCols memory vars,
            ColorUtils.ColScheme memory colScheme,
            GeomUtils.GeomSpec memory geomSpec,
            GeomUtils.GeomVars memory geomVars
        )
    {
        /// get this geom's spec
        geomSpec = GeomUtils.generateSpec(tokenHash);

        /// create the triangles
        (
            int256[3][3][] memory tris,
            int256[] memory zFronts,
            int256[] memory zBacks
        ) = create2dTris(tokenHash, geomSpec);

        /// prismify
        geomVars = prismify(tokenHash, tris, zFronts, zBacks);

        /// generate colored faces
        /// get a color scheme
        colScheme = ColorUtils.getScheme(tokenHash, tris);

        /// get faces, verts and colors
        vars = makeFacesVertsCols(
            tokenHash,
            tris,
            geomVars,
            colScheme,
            objPosition
        );
    }

    /** @dev 'randomly' create an array of 2d triangles that will define each eventual 3d prism  */
    function create2dTris(bytes32 tokenHash, GeomUtils.GeomSpec memory geomSpec)
        internal
        view
        returns (
            int256[3][3][] memory, /// tris
            int256[] memory, /// zFronts
            int256[] memory /// zBacks
        )
    {
        /// initiate vars that will be used to store the triangle info
        GeomUtils.TriVars memory triVars;
        triVars.tris = new int256[3][3][]((geomSpec.maxPrisms + 5) * 2);
        triVars.zFronts = new int256[]((geomSpec.maxPrisms + 5) * 2);
        triVars.zBacks = new int256[]((geomSpec.maxPrisms + 5) * 2);

        /// 'randomly' initiate the starting radius
        int256 initialSize;

        if (geomSpec.forceInitialSize == 0) {
            initialSize = GeomUtils.randN(
                tokenHash,
                "size",
                geomSpec.minTriRad,
                geomSpec.maxTriRad
            );
        } else {
            initialSize = geomSpec.forceInitialSize;
        }

        /// 50% chance of 30deg rotation, 50% chance of 210deg rotation
        int256 initialRot = GeomUtils.randN(tokenHash, "rot", 0, 1) == 0
            ? int256(30)
            : int256(210);

        /// create the first triangle
        int256[3][3] memory currentTri = GeomUtils.makeTri(
            [int256(0), 0, 0],
            initialSize,
            initialRot
        );

        /// save it
        triVars.tris[0] = currentTri;

        /// calculate the first triangle's zs
        triVars.zBacks[0] = GeomUtils.calculateZ(
            currentTri,
            tokenHash,
            triVars.nextTriIdx,
            geomSpec,
            false
        );
        triVars.zFronts[0] = GeomUtils.calculateZ(
            currentTri,
            tokenHash,
            triVars.nextTriIdx,
            geomSpec,
            true
        );

        /// get the position to add the next triangle

        if (geomSpec.isSymmetricY) {
            /// override the first tri, since it is not symmetrical
            /// but temporarily save it as its needed as a reference tri
            triVars.nextTriIdx = 0;
        } else {
            triVars.nextTriIdx = 1;
        }

        /// make new triangles
        for (uint256 i = 0; i < MAX_N_ATTEMPTS; i++) {
            /// get a reference to a previous triangle
            uint256 refIdx = uint256(
                GeomUtils.randN(
                    tokenHash,
                    string(abi.encodePacked("refIdx", i)),
                    0,
                    int256(triVars.nextTriIdx) - 1
                )
            );

            /// ensure that the 'random' number generated is different in each while loop
            /// by incorporating the nAttempts and nextTriIdx into the seed modifier
            if (
                GeomUtils.randN(
                    tokenHash,
                    string(abi.encodePacked("adj", i, triVars.nextTriIdx)),
                    0,
                    100
                ) <= geomSpec.probVertOpp
            ) {
                /// attempt to recursively add vertically opposite triangles
                triVars = GeomUtils.makeVerticallyOppositeTriangles(
                    tokenHash,
                    i, // attemptNum (to create unique random seeds)
                    refIdx,
                    triVars,
                    geomSpec,
                    -1,
                    -1,
                    0 // depth (to create unique random seeds within recursion)
                );
            } else {
                /// attempt to recursively add adjacent triangles
                triVars = GeomUtils.makeAdjacentTriangles(
                    tokenHash,
                    i, // attemptNum (to create unique random seeds)
                    refIdx,
                    triVars,
                    geomSpec,
                    -1,
                    -1,
                    0 // depth (to create unique random seeds within recursion)
                );
            }

            /// can't have this many triangles
            if (triVars.nextTriIdx >= geomSpec.maxPrisms) {
                break;
            }
        }

        /// clip all the arrays to the actual number of triangles
        triVars.tris = GeomUtils.clipTrisToLength(
            triVars.tris,
            triVars.nextTriIdx
        );
        triVars.zBacks = GeomUtils.clipZsToLength(
            triVars.zBacks,
            triVars.nextTriIdx
        );
        triVars.zFronts = GeomUtils.clipZsToLength(
            triVars.zFronts,
            triVars.nextTriIdx
        );

        return (triVars.tris, triVars.zBacks, triVars.zFronts);
    }

    /** @dev prismify the initial 2d triangles output */
    function prismify(
        bytes32 tokenHash,
        int256[3][3][] memory tris,
        int256[] memory zFronts,
        int256[] memory zBacks
    ) internal view returns (GeomUtils.GeomVars memory) {
        /// initialise a struct to hold the vars we need
        GeomUtils.GeomVars memory geomVars;

        /// record the num of prisms
        geomVars.nPrisms = uint256(tris.length);

        /// figure out what point to put in the middle
        geomVars.extents = GeomUtils.getExtents(tris); // mins[3], maxs[3]

        /// scale the tris to fit in the canvas
        geomVars.width = geomVars.extents[1][0] - geomVars.extents[0][0];
        geomVars.height = geomVars.extents[1][1] - geomVars.extents[0][1];
        geomVars.extent = ShackledMath.max(geomVars.width, geomVars.height);
        geomVars.scaleNum = 2000;

        /// multiple all tris by the scale, then divide by the extent
        for (uint256 i = 0; i < tris.length; i++) {
            tris[i] = [
                ShackledMath.vector3DivScalar(
                    ShackledMath.vector3MulScalar(
                        tris[i][0],
                        geomVars.scaleNum
                    ),
                    geomVars.extent
                ),
                ShackledMath.vector3DivScalar(
                    ShackledMath.vector3MulScalar(
                        tris[i][1],
                        geomVars.scaleNum
                    ),
                    geomVars.extent
                ),
                ShackledMath.vector3DivScalar(
                    ShackledMath.vector3MulScalar(
                        tris[i][2],
                        geomVars.scaleNum
                    ),
                    geomVars.extent
                )
            ];
        }

        /// we may like to do some rotation, this means we get the shapes in the middle
        /// arrow up, down, left, right

        // 50% chance of x, y rotation being positive or negative
        geomVars.rotX = (GeomUtils.randN(tokenHash, "rotX", 0, 1) == 0)
            ? ROT_XY_MAX
            : -ROT_XY_MAX;

        geomVars.rotY = (GeomUtils.randN(tokenHash, "rotY", 0, 1) == 0)
            ? ROT_XY_MAX
            : -ROT_XY_MAX;

        // 50% chance to z rotation being 0 or 30
        geomVars.rotZ = (GeomUtils.randN(tokenHash, "rotZ", 0, 1) == 0)
            ? int256(0)
            : int256(30);

        /// rotate all tris around facing (z) axis
        for (uint256 i = 0; i < tris.length; i++) {
            tris[i] = GeomUtils.triRotHelp(2, tris[i], geomVars.rotZ);
        }

        geomVars.trisBack = GeomUtils.copyTris(tris);
        geomVars.trisFront = GeomUtils.copyTris(tris);

        /// front triangles need to come forward, back triangles need to go back
        for (uint256 i = 0; i < tris.length; i++) {
            for (uint256 j = 0; j < 3; j++) {
                for (uint256 k = 0; k < 3; k++) {
                    if (k == 2) {
                        /// get the z values (make sure the scale is applied)
                        geomVars.trisFront[i][j][k] = zFronts[i];
                        geomVars.trisBack[i][j][k] = zBacks[i];
                    } else {
                        /// copy the x and y values
                        geomVars.trisFront[i][j][k] = tris[i][j][k];
                        geomVars.trisBack[i][j][k] = tris[i][j][k];
                    }
                }
            }
        }

        /// rotate - order is import here (must come after prism splitting, and is dependant on z rotation)
        if (geomVars.rotZ == 0) {
            /// x then y
            (geomVars.trisBack, geomVars.trisFront) = GeomUtils.triBfHelp(
                0,
                geomVars.trisBack,
                geomVars.trisFront,
                geomVars.rotX
            );
            (geomVars.trisBack, geomVars.trisFront) = GeomUtils.triBfHelp(
                1,
                geomVars.trisBack,
                geomVars.trisFront,
                geomVars.rotY
            );
        } else {
            /// y then x
            (geomVars.trisBack, geomVars.trisFront) = GeomUtils.triBfHelp(
                1,
                geomVars.trisBack,
                geomVars.trisFront,
                geomVars.rotY
            );
            (geomVars.trisBack, geomVars.trisFront) = GeomUtils.triBfHelp(
                0,
                geomVars.trisBack,
                geomVars.trisFront,
                geomVars.rotX
            );
        }

        return geomVars;
    }

    /** @dev create verts and faces out of the geom and get their colors */
    function makeFacesVertsCols(
        bytes32 tokenHash,
        int256[3][3][] memory tris,
        GeomUtils.GeomVars memory geomVars,
        ColorUtils.ColScheme memory scheme,
        int256[3] memory objPosition
    ) internal view returns (FacesVertsCols memory vars) {
        /// the tris defined thus far are those at the front of each prism
        /// we need to calculate how many tris will then be in the final prisms (3 sides have 2 tris each, plus the front tri, = 7)
        uint256 numTrisPrisms = tris.length * 7; /// 7 tris per 3D prism (not inc. back)

        vars.faces = new uint256[3][](numTrisPrisms); /// array that holds indexes of verts needed to make each final triangle
        vars.verts = new int256[3][](tris.length * 6); /// the vertices for all final triangles
        vars.cols = new int256[3][](tris.length * 6); /// 1 col per final tri
        vars.nextColIdx = 0;
        vars.nextVertIdx = 0;
        vars.nextFaceIdx = 0;

        /// get some number of highlight triangles
        geomVars.hltPrismIdx = ColorUtils.getHighlightPrismIdxs(
            tris,
            tokenHash,
            scheme.hltNum,
            scheme.hltVarCode,
            scheme.hltSelCode
        );

        int256[3][2] memory frontExtents = GeomUtils.getExtents(
            geomVars.trisFront
        ); // mins[3], maxs[3]
        int256[3][2] memory backExtents = GeomUtils.getExtents(
            geomVars.trisBack
        ); // mins[3], maxs[3]
        int256[3][2] memory meanExtents = [
            [
                (frontExtents[0][0] + backExtents[0][0]) / 2,
                (frontExtents[0][1] + backExtents[0][1]) / 2,
                (frontExtents[0][2] + backExtents[0][2]) / 2
            ],
            [
                (frontExtents[1][0] + backExtents[1][0]) / 2,
                (frontExtents[1][1] + backExtents[1][1]) / 2,
                (frontExtents[1][2] + backExtents[1][2]) / 2
            ]
        ];

        /// apply translations such that we're at the center
        geomVars.center = ShackledMath.vector3DivScalar(
            ShackledMath.vector3Add(meanExtents[0], meanExtents[1]),
            2
        );

        geomVars.center[2] = 0;

        for (uint256 i = 0; i < tris.length; i++) {
            int256[3][6] memory prismCols;
            ColorUtils.SubScheme memory subScheme = ColorUtils.inArray(
                geomVars.hltPrismIdx,
                i
            )
                ? scheme.hlt
                : scheme.pri;

            /// get the colors for the prism
            prismCols = ColorUtils.getColForPrism(
                tokenHash,
                geomVars.trisFront[i],
                subScheme,
                meanExtents
            );

            /// save the colors (6 per prism)
            for (uint256 j = 0; j < 6; j++) {
                vars.cols[vars.nextColIdx] = prismCols[j];
                vars.nextColIdx++;
            }

            /// add 3 points (back)
            for (uint256 j = 0; j < 3; j++) {
                vars.verts[vars.nextVertIdx] = [
                    geomVars.trisBack[i][j][0],
                    geomVars.trisBack[i][j][1],
                    -geomVars.trisBack[i][j][2] /// flip the Z
                ];
                vars.nextVertIdx += 1;
            }

            /// add 3 points (front)
            for (uint256 j = 0; j < 3; j++) {
                vars.verts[vars.nextVertIdx] = [
                    geomVars.trisFront[i][j][0],
                    geomVars.trisFront[i][j][1],
                    -geomVars.trisFront[i][j][2] /// flip the Z
                ];
                vars.nextVertIdx += 1;
            }

            /// create the faces
            uint256 ii = i * 6;

            /// the orders are all important here (back is not visible)

            /// front
            vars.faces[vars.nextFaceIdx] = [ii + 3, ii + 4, ii + 5];

            /// side 1 flat
            vars.faces[vars.nextFaceIdx + 1] = [ii + 4, ii + 3, ii + 0];
            vars.faces[vars.nextFaceIdx + 2] = [ii + 0, ii + 1, ii + 4];

            /// side 2 rhs
            vars.faces[vars.nextFaceIdx + 3] = [ii + 5, ii + 4, ii + 1];
            vars.faces[vars.nextFaceIdx + 4] = [ii + 1, ii + 2, ii + 5];

            /// side 3 lhs
            vars.faces[vars.nextFaceIdx + 5] = [ii + 2, ii + 0, ii + 3];
            vars.faces[vars.nextFaceIdx + 6] = [ii + 3, ii + 5, ii + 2];

            vars.nextFaceIdx += 7;
        }

        for (uint256 i = 0; i < vars.verts.length; i++) {
            vars.verts[i] = ShackledMath.vector3Sub(
                vars.verts[i],
                geomVars.center
            );
        }
    }
}

/** Hold some functions useful for coloring in the prisms  */
library ColorUtils {
    /// a struct to hold vars within the main color scheme
    /// which can be used for both highlight (hlt) an primar (pri) colors
    struct SubScheme {
        int256[3] colA; // either the entire solid color, or one side of the gradient
        int256[3] colB; // either the same as A (solid), or different (gradient)
        bool isInnerGradient; // whether the gradient spans the triangle (true) or canvas (false)
        int256 dirCode; // which direction should the gradient be interpolated
        int256[3] jiggle; // how much to randomly jiffle the color space
        bool isJiggleInner; // does each inner vertiex get a jiggle, or is it triangle wide
        int256[3] backShift; // how much to take off the back face colors
    }

    /// a struct for each piece's color scheme
    struct ColScheme {
        string name;
        uint256 id;
        /// the primary color
        SubScheme pri;
        /// the highlight color
        SubScheme hlt;
        /// remaining parameters (not common to hlt and pri)
        uint256 hltNum;
        int256 hltSelCode;
        int256 hltVarCode;
        /// other scene colors
        int256[3] lightCol;
        int256[3] bgColTop;
        int256[3] bgColBottom;
    }

    /** @dev calculate the color of a prism
    returns an array of 6 colors (for each vertex of a prism) 
     */
    function getColForPrism(
        bytes32 tokenHash,
        int256[3][3] memory triFront,
        SubScheme memory subScheme,
        int256[3][2] memory extents
    ) external view returns (int256[3][6] memory cols) {
        if (
            subScheme.colA[0] == subScheme.colB[0] &&
            subScheme.colA[1] == subScheme.colB[1] &&
            subScheme.colA[2] == subScheme.colB[2]
        ) {
            /// just use color A (as B is the same, so there's no gradient)
            for (uint256 i = 0; i < 6; i++) {
                cols[i] = copyColor(subScheme.colA);
            }
        } else {
            /// get the colors according to the direction code
            int256[3][3] memory triFrontCopy = GeomUtils.copyTri(triFront);
            int256[3][3] memory frontTriCols = applyDirHelp(
                triFrontCopy,
                subScheme.colA,
                subScheme.colB,
                subScheme.dirCode,
                subScheme.isInnerGradient,
                extents
            );

            /// write in the same front colors as the back colors
            for (uint256 i = 0; i < 3; i++) {
                cols[i] = copyColor(frontTriCols[i]);
                cols[i + 3] = copyColor(frontTriCols[i]);
            }
        }

        /// perform the jiggling
        int256[3] memory jiggle;

        if (!subScheme.isJiggleInner) {
            /// get one set of jiggle values to use for all colors created
            jiggle = getJiggle(subScheme.jiggle, tokenHash, 0);
        }

        for (uint256 i = 0; i < 6; i++) {
            if (subScheme.isJiggleInner) {
                // jiggle again per col to create
                // use the last jiggle res in the random seed to get diff jiggles for each prism
                jiggle = getJiggle(subScheme.jiggle, tokenHash, jiggle[0]);
            }

            /// convert to hsv prior to jiggle
            int256[3] memory colHsv = rgb2hsv(
                cols[i][0],
                cols[i][1],
                cols[i][2]
            );

            /// add the jiggle to the colors in hsv space
            colHsv[0] = colHsv[0] + jiggle[0];
            colHsv[1] = colHsv[1] + jiggle[1];
            colHsv[2] = colHsv[2] + jiggle[2];

            /// convert back to rgb
            int256[3] memory colRgb = hsv2rgb(colHsv[0], colHsv[1], colHsv[2]);
            cols[i][0] = colRgb[0];
            cols[i][1] = colRgb[1];
            cols[i][2] = colRgb[2];
        }

        /// perform back shifting
        for (uint256 i = 0; i < 3; i++) {
            cols[i][0] -= subScheme.backShift[0];
            cols[i][1] -= subScheme.backShift[1];
            cols[i][2] -= subScheme.backShift[2];
        }

        /// ensure that we're in 255 range
        for (uint256 i = 0; i < 6; i++) {
            cols[i][0] = ShackledMath.max(0, ShackledMath.min(255, cols[i][0]));
            cols[i][1] = ShackledMath.max(0, ShackledMath.min(255, cols[i][1]));
            cols[i][2] = ShackledMath.max(0, ShackledMath.min(255, cols[i][2]));
        }

        return cols;
    }

    /** @dev roll a schemeId given a list of weightings */
    function getSchemeId(bytes32 tokenHash, int256[2][10] memory weightings)
        internal
        view
        returns (uint256)
    {
        int256 n = GeomUtils.randN(
            tokenHash,
            "schemedId",
            weightings[0][0],
            weightings[weightings.length - 1][1]
        );
        for (uint256 i = 0; i < weightings.length; i++) {
            if (weightings[i][0] <= n && n <= weightings[i][1]) {
                return i;
            }
        }
    }

    /** @dev make a copy of a color */
    function copyColor(int256[3] memory c)
        internal
        view
        returns (int256[3] memory)
    {
        return [c[0], c[1], c[2]];
    }

    /** @dev get a color scheme */
    function getScheme(bytes32 tokenHash, int256[3][3][] memory tris)
        external
        view
        returns (ColScheme memory colScheme)
    {
        /// 'randomly' select 1 of the 9 schemes
        uint256 schemeId = getSchemeId(
            tokenHash,
            [
                [int256(0), 1500],
                [int256(1500), 2500],
                [int256(2500), 3000],
                [int256(3000), 3100],
                [int256(3100), 5500],
                [int256(5500), 6000],
                [int256(6000), 6500],
                [int256(6500), 8000],
                [int256(8000), 9500],
                [int256(9500), 10000]
            ]
        );

        // int256 schemeId = GeomUtils.randN(tokenHash, "schemeID", 1, 9);

        /// define the color scheme to use for this piece
        /// all arrays are on the order of 1000 to remain accurate as integers
        /// will require division by 1000 later when in use

        if (schemeId == 0) {
            /// plain / beigey with a highlight, and a matching background colour
            colScheme = ColScheme({
                name: "Accentuated",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(60), 30, 25],
                    colB: [int256(205), 205, 205],
                    isInnerGradient: false,
                    dirCode: 0,
                    jiggle: [int256(13), 13, 13],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hlt: SubScheme({
                    colA: [int256(255), 0, 0],
                    colB: [int256(255), 50, 0],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "hltDir", 0, 3), /// get a 'random' dir code
                    jiggle: [int256(50), 50, 50],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hltNum: uint256(GeomUtils.randN(tokenHash, "hltNum", 3, 5)), /// get a 'random' number of highlights between 3 and 5
                hltSelCode: 1, /// 'biggest' selection code
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(0), 0, 0],
                bgColBottom: [int256(1), 1, 1]
            });
        } else if (schemeId == 1) {
            /// neutral overall
            colScheme = ColScheme({
                name: "Emergent",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(0), 77, 255],
                    colB: [int256(0), 255, 25],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "priDir", 2, 3), /// get a 'random' dir code (2 or 3)
                    jiggle: [int256(60), 60, 60],
                    isJiggleInner: false,
                    backShift: [int256(-255), -255, -255]
                }),
                hlt: SubScheme({
                    colA: [int256(0), 77, 255],
                    colB: [int256(0), 255, 25],
                    isInnerGradient: true,
                    dirCode: 3,
                    jiggle: [int256(60), 60, 60],
                    isJiggleInner: false,
                    backShift: [int256(-255), -255, -255]
                }),
                hltNum: uint256(GeomUtils.randN(tokenHash, "hltNum", 4, 6)), /// get a 'random' number of highlights between 4 and 6
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(255), 255, 255],
                bgColBottom: [int256(255), 255, 255]
            });
        } else if (schemeId == 2) {
            /// vaporwave
            int256 maxHighlights = ShackledMath.max(0, int256(tris.length) - 8);
            int256 minHighlights = ShackledMath.max(
                0,
                int256(maxHighlights) - 2
            );
            colScheme = ColScheme({
                name: "Sunset",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(179), 0, 179],
                    colB: [int256(0), 0, 255],
                    isInnerGradient: false,
                    dirCode: 2, /// up-down
                    jiggle: [int256(25), 25, 25],
                    isJiggleInner: true,
                    backShift: [int256(127), 127, 127]
                }),
                hlt: SubScheme({
                    colA: [int256(0), 0, 0],
                    colB: [int256(0), 0, 0],
                    isInnerGradient: true,
                    dirCode: 3, /// down-up
                    jiggle: [int256(15), 0, 15],
                    isJiggleInner: true,
                    backShift: [int256(0), 0, 0]
                }),
                hltNum: uint256(
                    GeomUtils.randN(
                        tokenHash,
                        "hltNum",
                        minHighlights,
                        maxHighlights
                    )
                ), /// get a 'random' number of highlights between minHighlights and maxHighlights
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(250), 103, 247],
                bgColBottom: [int256(157), 104, 250]
            });
        } else if (schemeId == 3) {
            /// gold
            int256 priDirCode = GeomUtils.randN(tokenHash, "pirDir", 0, 1); /// get a 'random' dir code (0 or 1)
            colScheme = ColScheme({
                name: "Stone & Gold",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(50), 50, 50],
                    colB: [int256(100), 100, 100],
                    isInnerGradient: true,
                    dirCode: priDirCode,
                    jiggle: [int256(10), 10, 10],
                    isJiggleInner: true,
                    backShift: [int256(128), 128, 128]
                }),
                hlt: SubScheme({
                    colA: [int256(255), 197, 0],
                    colB: [int256(255), 126, 0],
                    isInnerGradient: true,
                    dirCode: priDirCode,
                    jiggle: [int256(0), 0, 0],
                    isJiggleInner: false,
                    backShift: [int256(64), 64, 64]
                }),
                hltNum: 1,
                hltSelCode: 1, /// biggest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(0), 0, 0],
                bgColBottom: [int256(0), 0, 0]
            });
        } else if (schemeId == 4) {
            /// random pastel colors (sometimes black)
            /// for primary colors,
            /// follow the pattern of making a new and unique seedHash for each variable
            /// so they are independant
            /// seed modifiers = pri/hlt + a/b + /r/g/b
            colScheme = ColScheme({
                name: "Denatured",
                id: schemeId,
                pri: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "PAR", 25, 255),
                        GeomUtils.randN(tokenHash, "PAG", 25, 255),
                        GeomUtils.randN(tokenHash, "PAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "PBR", 25, 255),
                        GeomUtils.randN(tokenHash, "PBG", 25, 255),
                        GeomUtils.randN(tokenHash, "PBB", 25, 255)
                    ],
                    isInnerGradient: false,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 1), /// get a 'random' dir code (0 or 1)
                    jiggle: [int256(0), 0, 0],
                    isJiggleInner: false,
                    backShift: [int256(127), 127, 127]
                }),
                hlt: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "HAR", 25, 255),
                        GeomUtils.randN(tokenHash, "HAG", 25, 255),
                        GeomUtils.randN(tokenHash, "HAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "HBR", 25, 255),
                        GeomUtils.randN(tokenHash, "HBG", 25, 255),
                        GeomUtils.randN(tokenHash, "HBB", 25, 255)
                    ],
                    isInnerGradient: false,
                    dirCode: GeomUtils.randN(tokenHash, "hlt", 0, 1), /// get a 'random' dir code (0 or 1)
                    jiggle: [int256(0), 0, 0],
                    isJiggleInner: false,
                    backShift: [int256(127), 127, 127]
                }),
                hltNum: tris.length / 2,
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(3), 3, 3],
                bgColBottom: [int256(0), 0, 0]
            });
        } else if (schemeId == 5) {
            /// inter triangle random colors ('chameleonic')

            /// pri dir code is anything (0, 1, 2, 3)
            /// hlt dir code is oppose to pri dir code (rl <-> lr, up <-> du)
            int256 priDirCode = GeomUtils.randN(tokenHash, "pri", 0, 3); /// get a 'random' dir code (0 or 1)
            int256 hltDirCode;
            if (priDirCode == 0 || priDirCode == 1) {
                hltDirCode = priDirCode == 0 ? int256(1) : int256(0);
            } else {
                hltDirCode = priDirCode == 2 ? int256(3) : int256(2);
            }
            /// for primary colors,
            /// follow the pattern of making a new and unique seedHash for each variable
            /// so they are independant
            /// seed modifiers = pri/hlt + a/b + /r/g/b
            colScheme = ColScheme({
                name: "Chameleonic",
                id: schemeId,
                pri: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "PAR", 25, 255),
                        GeomUtils.randN(tokenHash, "PAG", 25, 255),
                        GeomUtils.randN(tokenHash, "PAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "PBR", 25, 255),
                        GeomUtils.randN(tokenHash, "PBG", 25, 255),
                        GeomUtils.randN(tokenHash, "PBB", 25, 255)
                    ],
                    isInnerGradient: true,
                    dirCode: priDirCode,
                    jiggle: [int256(25), 25, 25],
                    isJiggleInner: true,
                    backShift: [int256(0), 0, 0]
                }),
                hlt: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "HAR", 25, 255),
                        GeomUtils.randN(tokenHash, "HAG", 25, 255),
                        GeomUtils.randN(tokenHash, "HAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "HBR", 25, 255),
                        GeomUtils.randN(tokenHash, "HBG", 25, 255),
                        GeomUtils.randN(tokenHash, "HBB", 25, 255)
                    ],
                    isInnerGradient: true,
                    dirCode: hltDirCode,
                    jiggle: [int256(255), 255, 255],
                    isJiggleInner: true,
                    backShift: [int256(205), 205, 205]
                }),
                hltNum: 12,
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(3), 3, 3],
                bgColBottom: [int256(0), 0, 0]
            });
        } else if (schemeId == 6) {
            /// each prism is a different colour with some randomisation

            /// pri dir code is anything (0, 1, 2, 3)
            /// hlt dir code is oppose to pri dir code (rl <-> lr, up <-> du)
            int256 priDirCode = GeomUtils.randN(tokenHash, "pri", 0, 1); /// get a 'random' dir code (0 or 1)
            int256 hltDirCode;
            if (priDirCode == 0 || priDirCode == 1) {
                hltDirCode = priDirCode == 0 ? int256(1) : int256(0);
            } else {
                hltDirCode = priDirCode == 2 ? int256(3) : int256(2);
            }
            /// for primary colors,
            /// follow the pattern of making a new and unique seedHash for each variable
            /// so they are independant
            /// seed modifiers = pri/hlt + a/b + /r/g/b
            colScheme = ColScheme({
                name: "Gradiated",
                id: schemeId,
                pri: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "PAR", 25, 255),
                        GeomUtils.randN(tokenHash, "PAG", 25, 255),
                        GeomUtils.randN(tokenHash, "PAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "PBR", 25, 255),
                        GeomUtils.randN(tokenHash, "PBG", 25, 255),
                        GeomUtils.randN(tokenHash, "PBB", 25, 255)
                    ],
                    isInnerGradient: false,
                    dirCode: priDirCode,
                    jiggle: [int256(127), 127, 127],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hlt: SubScheme({
                    colA: [
                        GeomUtils.randN(tokenHash, "HAR", 25, 255),
                        GeomUtils.randN(tokenHash, "HAG", 25, 255),
                        GeomUtils.randN(tokenHash, "HAB", 25, 255)
                    ],
                    colB: [
                        GeomUtils.randN(tokenHash, "HBR", 25, 255),
                        GeomUtils.randN(tokenHash, "HBG", 25, 255),
                        GeomUtils.randN(tokenHash, "HBB", 25, 255)
                    ],
                    isInnerGradient: false,
                    dirCode: hltDirCode,
                    jiggle: [int256(127), 127, 127],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hltNum: 12, /// get a 'random' number of highlights between 4 and 6
                hltSelCode: 2, /// smallest-first
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(3), 3, 3],
                bgColBottom: [int256(0), 0, 0]
            });
        } else if (schemeId == 7) {
            /// feature colour on white primary, with feature colour background
            /// calculate the feature color in hsv
            int256[3] memory hsv = [
                GeomUtils.randN(tokenHash, "hsv", 0, 255),
                230,
                255
            ];
            int256[3] memory hltColA = hsv2rgb(hsv[0], hsv[1], hsv[2]);

            colScheme = ColScheme({
                name: "Vivid Alabaster",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(255), 255, 255],
                    colB: [int256(255), 255, 255],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 3), /// get a 'random' dir code (0 or 1)
                    jiggle: [int256(25), 25, 25],
                    isJiggleInner: true,
                    backShift: [int256(127), 127, 127]
                }),
                hlt: SubScheme({
                    colA: hltColA,
                    colB: copyColor(hltColA), /// same as A
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 3), /// same as priDirCode
                    jiggle: [int256(25), 50, 50],
                    isJiggleInner: true,
                    backShift: [int256(180), 180, 180]
                }),
                hltNum: tris.length % 2 == 1
                    ? (tris.length / 2) + 1
                    : tris.length / 2,
                hltSelCode: GeomUtils.randN(tokenHash, "hltSel", 0, 2),
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: hsv2rgb(
                    ShackledMath.mod((hsv[0] - 9), 255),
                    105,
                    255
                ),
                bgColBottom: hsv2rgb(
                    ShackledMath.mod((hsv[0] + 9), 255),
                    105,
                    255
                )
            });
        } else if (schemeId == 8) {
            /// feature colour on black primary, with feature colour background
            /// calculate the feature color in hsv
            int256[3] memory hsv = [
                GeomUtils.randN(tokenHash, "hsv", 0, 255),
                245,
                190
            ];

            int256[3] memory hltColA = hsv2rgb(hsv[0], hsv[1], hsv[2]);

            colScheme = ColScheme({
                name: "Vivid Ink",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(0), 0, 0],
                    colB: [int256(0), 0, 0],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 3), /// get a 'random' dir code (0 or 1)
                    jiggle: [int256(25), 25, 25],
                    isJiggleInner: false,
                    backShift: [int256(-60), -60, -60]
                }),
                hlt: SubScheme({
                    colA: hltColA,
                    colB: copyColor(hltColA), /// same as A
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "pri", 0, 3), /// same as priDirCode
                    jiggle: [int256(0), 0, 0],
                    isJiggleInner: false,
                    backShift: [int256(-60), -60, -60]
                }),
                hltNum: tris.length % 2 == 1
                    ? (tris.length / 2) + 1
                    : tris.length / 2,
                hltSelCode: GeomUtils.randN(tokenHash, "hltSel", 0, 2),
                hltVarCode: GeomUtils.randN(tokenHash, "hltVar", 0, 2),
                lightCol: [int256(255), 255, 255],
                bgColTop: hsv2rgb(
                    ShackledMath.mod((hsv[0] - 9), 255),
                    105,
                    255
                ),
                bgColBottom: hsv2rgb(
                    ShackledMath.mod((hsv[0] + 9), 255),
                    105,
                    255
                )
            });
        } else if (schemeId == 9) {
            colScheme = ColScheme({
                name: "Pigmented",
                id: schemeId,
                pri: SubScheme({
                    colA: [int256(50), 30, 25],
                    colB: [int256(205), 205, 205],
                    isInnerGradient: false,
                    dirCode: 0,
                    jiggle: [int256(13), 13, 13],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hlt: SubScheme({
                    colA: [int256(255), 0, 0],
                    colB: [int256(255), 50, 0],
                    isInnerGradient: true,
                    dirCode: GeomUtils.randN(tokenHash, "hltDir", 0, 3), /// get a 'random' dir code
                    jiggle: [int256(255), 50, 50],
                    isJiggleInner: false,
                    backShift: [int256(205), 205, 205]
                }),
                hltNum: tris.length / 3,
                hltSelCode: 1, /// 'biggest' selection code
                hltVarCode: 0,
                lightCol: [int256(255), 255, 255],
                bgColTop: [int256(0), 0, 0],
                bgColBottom: [int256(7), 7, 7]
            });
        } else {
            revert("invalid scheme id");
        }

        return colScheme;
    }

    /** @dev convert hsv to rgb color
    assume h, s and v and in range [0, 255]
    outputs rgb in range [0, 255]
     */
    function hsv2rgb(
        int256 h,
        int256 s,
        int256 v
    ) internal view returns (int256[3] memory res) {
        /// ensure range 0, 255
        h = ShackledMath.max(0, ShackledMath.min(255, h));
        s = ShackledMath.max(0, ShackledMath.min(255, s));
        v = ShackledMath.max(0, ShackledMath.min(255, v));

        int256 h2 = (((h % 255) * 1e3) / 255) * 360; /// convert to degress
        int256 v2 = (v * 1e3) / 255;
        int256 s2 = (s * 1e3) / 255;

        /// calculate c, x and m while scaling all by 1e3
        /// otherwise x will be too small and round to 0
        int256 c = (v2 * s2) / 1e3;

        int256 x = (c *
            (1 * 1e3 - ShackledMath.abs(((h2 / 60) % (2 * 1e3)) - (1 * 1e3))));

        x = x / 1e3;

        int256 m = v2 - c;

        if (0 <= h2 && h2 < 60000) {
            res = [c + m, x + m, m];
        } else if (60000 <= h2 && h2 < 120000) {
            res = [x + m, c + m, m];
        } else if (120000 < h2 && h2 < 180000) {
            res = [m, c + m, x + m];
        } else if (180000 < h2 && h2 < 240000) {
            res = [m, x + m, c + m];
        } else if (240000 < h2 && h2 < 300000) {
            res = [x + m, m, c + m];
        } else if (300000 < h2 && h2 < 360000) {
            res = [c + m, m, x + m];
        } else {
            res = [int256(0), 0, 0];
        }

        /// scale into correct range
        return [
            (res[0] * 255) / 1e3,
            (res[1] * 255) / 1e3,
            (res[2] * 255) / 1e3
        ];
    }

    /** @dev convert rgb to hsv 
        expects rgb to be in range [0, 255]
        outputs hsv in range [0, 255]
    */
    function rgb2hsv(
        int256 r,
        int256 g,
        int256 b
    ) internal view returns (int256[3] memory) {
        int256 r2 = (r * 1e3) / 255;
        int256 g2 = (g * 1e3) / 255;
        int256 b2 = (b * 1e3) / 255;
        int256 max = ShackledMath.max(ShackledMath.max(r2, g2), b2);
        int256 min = ShackledMath.min(ShackledMath.min(r2, g2), b2);
        int256 delta = max - min;

        /// calculate hue
        int256 h;
        if (delta != 0) {
            if (max == r2) {
                int256 _h = ((g2 - b2) * 1e3) / delta;
                h = 60 * ShackledMath.mod(_h, 6000);
            } else if (max == g2) {
                h = 60 * (((b2 - r2) * 1e3) / delta + (2000));
            } else if (max == b2) {
                h = 60 * (((r2 - g2) * 1e3) / delta + (4000));
            }
        }

        h = (h % (360 * 1e3)) / 360;

        /// calculate saturation
        int256 s;
        if (max != 0) {
            s = (delta * 1e3) / max;
        }

        /// calculate value
        int256 v = max;

        return [(h * 255) / 1e3, (s * 255) / 1e3, (v * 255) / 1e3];
    }

    /** @dev get vector of three numbers that can be used to jiggle a color */
    function getJiggle(
        int256[3] memory jiggle,
        bytes32 randomSeed,
        int256 seedModifier
    ) internal view returns (int256[3] memory) {
        return [
            jiggle[0] +
                GeomUtils.randN(
                    randomSeed,
                    string(abi.encodePacked("0", seedModifier)),
                    -jiggle[0],
                    jiggle[0]
                ),
            jiggle[1] +
                GeomUtils.randN(
                    randomSeed,
                    string(abi.encodePacked("1", seedModifier)),
                    -jiggle[1],
                    jiggle[1]
                ),
            jiggle[2] +
                GeomUtils.randN(
                    randomSeed,
                    string(abi.encodePacked("2", seedModifier)),
                    -jiggle[2],
                    jiggle[2]
                )
        ];
    }

    /** @dev check if a uint is in an array */
    function inArray(uint256[] memory array, uint256 value)
        external
        view
        returns (bool)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    /** @dev a helper function to apply the direction code in interpolation */
    function applyDirHelp(
        int256[3][3] memory triFront,
        int256[3] memory colA,
        int256[3] memory colB,
        int256 dirCode,
        bool isInnerGradient,
        int256[3][2] memory extents
    ) internal view returns (int256[3][3] memory triCols) {
        uint256[3] memory order;
        if (isInnerGradient) {
            /// perform the simple 3 sort - always color by the front
            order = getOrderedPointIdxsInDir(triFront, dirCode);
        } else {
            /// order irrelevant in other case
            order = [uint256(0), 1, 2];
        }

        /// axis is 0 (horizontal) if dir code is left-right or right-left
        /// 1 (vertical) otherwise
        uint256 axis = (dirCode == 0 || dirCode == 1) ? 0 : 1;

        int256 length;
        if (axis == 0) {
            length = extents[1][0] - extents[0][0];
        } else {
            length = extents[1][1] - extents[0][1];
        }

        /// if we're interpolating across the triangle (inner)
        /// then do so by calculating the color at each point in the triangle
        for (uint256 i = 0; i < 3; i++) {
            triCols[order[i]] = interpColHelp(
                colA,
                colB,
                (isInnerGradient)
                    ? triFront[order[0]][axis]
                    : int256(-length / 2),
                (isInnerGradient)
                    ? triFront[order[2]][axis]
                    : int256(length / 2),
                triFront[order[i]][axis]
            );
        }
    }

    /** @dev a helper function to order points by index in a desired direction
     */
    function getOrderedPointIdxsInDir(int256[3][3] memory tri, int256 dirCode)
        internal
        view
        returns (uint256[3] memory)
    {
        // flip if dir is left-right or down-up
        bool flip = (dirCode == 1 || dirCode == 3) ? true : false;

        // axis is 0 if horizontal (left-right or right-left), 1 otherwise (vertical)
        uint256 axis = (dirCode == 0 || dirCode == 1) ? 0 : 1;

        /// get the values of each point in the tri (flipped as required)
        int256 f = (flip) ? int256(-1) : int256(1);
        int256 a = f * tri[0][axis];
        int256 b = f * tri[1][axis];
        int256 c = f * tri[2][axis];

        /// get the ordered indices
        uint256[3] memory ixOrd = [uint256(0), 1, 2];

        /// simplest way to sort 3 numbers
        if (a > b) {
            (a, b) = (b, a);
            (ixOrd[0], ixOrd[1]) = (ixOrd[1], ixOrd[0]);
        }
        if (a > c) {
            (a, c) = (c, a);
            (ixOrd[0], ixOrd[2]) = (ixOrd[2], ixOrd[0]);
        }
        if (b > c) {
            (b, c) = (c, b);
            (ixOrd[1], ixOrd[2]) = (ixOrd[2], ixOrd[1]);
        }
        return ixOrd;
    }

    /** @dev a helper function for linear interpolation betweet two colors*/
    function interpColHelp(
        int256[3] memory colA,
        int256[3] memory colB,
        int256 low,
        int256 high,
        int256 val
    ) internal view returns (int256[3] memory result) {
        int256 ir;
        int256 lerpScaleFactor = 1e3;
        if (high - low == 0) {
            ir = 1;
        } else {
            ir = ((val - low) * lerpScaleFactor) / (high - low);
        }

        for (uint256 i = 0; i < 3; i++) {
            /// dont allow interpolation to go below 0
            result[i] = ShackledMath.max(
                0,
                colA[i] + ((colB[i] - colA[i]) * ir) / lerpScaleFactor
            );
        }
    }

    /** @dev get indexes of the prisms to use highlight coloring*/
    function getHighlightPrismIdxs(
        int256[3][3][] memory tris,
        bytes32 tokenHash,
        uint256 nHighlights,
        int256 varCode,
        int256 selCode
    ) internal view returns (uint256[] memory idxs) {
        nHighlights = nHighlights < tris.length ? nHighlights : tris.length;

        ///if we just want random triangles then there's no need to sort
        if (selCode == 0) {
            idxs = ShackledMath.randomIdx(
                tokenHash,
                uint256(nHighlights),
                tris.length - 1
            );
        } else {
            idxs = getSortedTrisIdxs(tris, nHighlights, varCode, selCode);
        }
    }

    /** @dev return the index of the tris sorted by sel code
    @param selCode will be 1 (biggest first) or 2 (smallest first)
    */
    function getSortedTrisIdxs(
        int256[3][3][] memory tris,
        uint256 nHighlights,
        int256 varCode,
        int256 selCode
    ) internal view returns (uint256[] memory) {
        // determine the sort order
        int256 orderFactor = (selCode == 2) ? int256(1) : int256(-1);
        /// get the list of triangle sizes
        int256[] memory sizes = new int256[](tris.length);
        for (uint256 i = 0; i < tris.length; i++) {
            if (varCode == 0) {
                // use size
                sizes[i] = GeomUtils.getRadiusLen(tris[i]) * orderFactor;
            } else if (varCode == 1) {
                // use x
                sizes[i] = GeomUtils.getCenterVec(tris[i])[0] * orderFactor;
            } else if (varCode == 2) {
                // use y
                sizes[i] = GeomUtils.getCenterVec(tris[i])[1] * orderFactor;
            }
        }
        /// initialise the index array
        uint256[] memory idxs = new uint256[](tris.length);
        for (uint256 i = 0; i < tris.length; i++) {
            idxs[i] = i;
        }
        /// run a boilerplate insertion sort over the index array
        for (uint256 i = 1; i < tris.length; i++) {
            int256 key = sizes[i];
            uint256 j = i - 1;
            while (j > 0 && key < sizes[j]) {
                sizes[j + 1] = sizes[j];
                idxs[j + 1] = idxs[j];
                j--;
            }
            sizes[j + 1] = key;
            idxs[j + 1] = i;
        }

        uint256 nToCull = tris.length - nHighlights;
        assembly {
            mstore(idxs, sub(mload(idxs), nToCull))
        }

        return idxs;
    }
}

/**
Hold some functions externally to reduce contract size for mainnet deployment
 */
library GeomUtils {
    /// misc constants
    int256 constant MIN_INT = type(int256).min;
    int256 constant MAX_INT = type(int256).max;

    /// constants for doing trig
    int256 constant PI = 3141592653589793238; // pi as an 18 decimal value (wad)

    /// parameters that control geometry creation
    struct GeomSpec {
        string name;
        int256 id;
        int256 forceInitialSize;
        uint256 maxPrisms;
        int256 minTriRad;
        int256 maxTriRad;
        bool varySize;
        int256 depthMultiplier;
        bool isSymmetricX;
        bool isSymmetricY;
        int256 probVertOpp;
        int256 probAdjRec;
        int256 probVertOppRec;
    }

    /// variables uses when creating the initial 2d triangles
    struct TriVars {
        uint256 nextTriIdx;
        int256[3][3][] tris;
        int256[3][3] tri;
        int256 zBackRef;
        int256 zFrontRef;
        int256[] zFronts;
        int256[] zBacks;
        bool recursiveAttempt;
    }

    /// variables used when creating 3d prisms
    struct GeomVars {
        int256 rotX;
        int256 rotY;
        int256 rotZ;
        int256[3][2] extents;
        int256[3] center;
        int256 width;
        int256 height;
        int256 extent;
        int256 scaleNum;
        uint256[] hltPrismIdx;
        int256[3][3][] trisBack;
        int256[3][3][] trisFront;
        uint256 nPrisms;
    }

    /** @dev generate parameters that will control how the geometry is built */
    function generateSpec(bytes32 tokenHash)
        external
        view
        returns (GeomSpec memory spec)
    {
        //  'randomly' select 1 of possible geometry specifications
        uint256 specId = getSpecId(
            tokenHash,
            [
                [int256(0), 1000],
                [int256(1000), 3000],
                [int256(3000), 3500],
                [int256(3500), 4500],
                [int256(4500), 5000],
                [int256(5000), 6000],
                [int256(6000), 8000]
            ]
        );

        bool isSymmetricX = GeomUtils.randN(tokenHash, "symmX", 0, 2) > 0;
        bool isSymmetricY = GeomUtils.randN(tokenHash, "symmY", 0, 2) > 0;

        int256 defaultDepthMultiplier = randN(tokenHash, "depthMult", 80, 120);
        int256 defaultMinTriRad = 4800;
        int256 defaultMaxTriRad = defaultMinTriRad * 3;
        uint256 defaultMaxPrisms = uint256(
            randN(tokenHash, "maxPrisms", 8, 16)
        );

        if (specId == 0) {
            /// all vertically opposite
            spec = GeomSpec({
                id: 0,
                name: "Verticalized",
                forceInitialSize: (defaultMinTriRad * 5) / 2,
                maxPrisms: defaultMaxPrisms,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 100,
                probVertOppRec: 100,
                probAdjRec: 0,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 1) {
            /// fully adjacent
            spec = GeomSpec({
                id: 1,
                name: "Adjoint",
                forceInitialSize: (defaultMinTriRad * 5) / 2,
                maxPrisms: defaultMaxPrisms,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 0,
                probVertOppRec: 0,
                probAdjRec: 100,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 2) {
            /// few but big
            spec = GeomSpec({
                id: 2,
                name: "Cetacean",
                forceInitialSize: 0,
                maxPrisms: 8,
                minTriRad: defaultMinTriRad * 3,
                maxTriRad: defaultMinTriRad * 4,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 50,
                probAdjRec: 50,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 3) {
            /// lots but small
            spec = GeomSpec({
                id: 3,
                name: "Swarm",
                forceInitialSize: 0,
                maxPrisms: 16,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMinTriRad * 2,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 0,
                probAdjRec: 0,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 4) {
            /// all same size
            spec = GeomSpec({
                id: 4,
                name: "Isomorphic",
                forceInitialSize: 0,
                maxPrisms: defaultMaxPrisms,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: false,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 50,
                probAdjRec: 50,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 5) {
            /// trains
            spec = GeomSpec({
                id: 5,
                name: "Extruded",
                forceInitialSize: 0,
                maxPrisms: 10,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 50,
                probAdjRec: 50,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else if (specId == 6) {
            /// flatpack
            spec = GeomSpec({
                id: 6,
                name: "Uniform",
                forceInitialSize: 0,
                maxPrisms: 12,
                minTriRad: defaultMinTriRad,
                maxTriRad: defaultMaxTriRad,
                varySize: true,
                depthMultiplier: defaultDepthMultiplier,
                probVertOpp: 50,
                probVertOppRec: 50,
                probAdjRec: 50,
                isSymmetricX: isSymmetricX,
                isSymmetricY: isSymmetricY
            });
        } else {
            revert("invalid specId");
        }
    }

    /** @dev make triangles to the side of a reference triangle */
    function makeAdjacentTriangles(
        bytes32 tokenHash,
        uint256 attemptNum,
        uint256 refIdx,
        TriVars memory triVars,
        GeomSpec memory geomSpec,
        int256 overrideSideIdx,
        int256 overrideScale,
        int256 depth
    ) public view returns (TriVars memory) {
        /// get the side index (0, 1 or 2)
        int256 sideIdx;
        if (overrideSideIdx == -1) {
            sideIdx = randN(
                tokenHash,
                string(abi.encodePacked("sideIdx", attemptNum, depth)),
                0,
                2
            );
        } else {
            sideIdx = overrideSideIdx;
        }

        /// get the scale
        /// this value is scaled up by 1e3 (desired range is 0.333 to 0.8)
        /// the scale will be divided out when used
        int256 scale;
        if (geomSpec.varySize) {
            if (overrideScale == -1) {
                scale = randN(
                    tokenHash,
                    string(abi.encodePacked("scaleAdj", attemptNum, depth)),
                    333,
                    800
                );
            } else {
                scale = overrideScale;
            }
        } else {
            scale = 1e3;
        }

        /// make a new triangle
        int256[3][3] memory newTri = makeTriAdjacent(
            tokenHash,
            geomSpec,
            attemptNum,
            triVars.tris[refIdx],
            sideIdx,
            scale,
            depth
        );

        /// set the zbackref and frontbackref
        triVars.zBackRef = -1; /// calculate a new z back
        triVars.zFrontRef = -1; /// calculate a new z ftont

        // try to add the triangle, and use the reference z height
        triVars.recursiveAttempt = false;
        bool wasAdded = attemptToAddTri(newTri, tokenHash, triVars, geomSpec);

        if (wasAdded) {
            // run again
            if (
                randN(
                    tokenHash,
                    string(
                        abi.encodePacked("addAdjRecursive", attemptNum, depth)
                    ),
                    0,
                    100
                ) <= geomSpec.probAdjRec
            ) {
                triVars = makeAdjacentTriangles(
                    tokenHash,
                    attemptNum,
                    triVars.nextTriIdx - 1,
                    triVars,
                    geomSpec,
                    sideIdx,
                    666, /// always make the next one 2/3 scale
                    depth + 1
                );
            }
        }
        return triVars;
    }

    /** @dev make triangles vertically opposite a reference triangle */
    function makeVerticallyOppositeTriangles(
        bytes32 tokenHash,
        uint256 attemptNum,
        uint256 refIdx,
        TriVars memory triVars,
        GeomSpec memory geomSpec,
        int256 overrideSideIdx,
        int256 overrideScale,
        int256 depth
    ) public view returns (TriVars memory) {
        /// get the side index (0, 1 or 2)
        int256 sideIdx;
        if (overrideSideIdx == -1) {
            sideIdx = randN(
                tokenHash,
                string(abi.encodePacked("vertOppSideIdx", attemptNum, depth)),
                0,
                2
            );
        } else {
            sideIdx = overrideSideIdx;
        }

        /// get the scale
        /// this value is scaled up by 1e3
        /// use attemptNum in seedModifier to ensure unique values each attempt
        int256 scale;
        if (geomSpec.varySize) {
            if (overrideScale == -1) {
                if (
                    // prettier-ignore
                    randN(
                        tokenHash,
                        string(abi.encodePacked("vertOppScale1", attemptNum, depth)),
                        0,
                        100
                    ) > 33
                ) {
                    // prettier-ignore
                    if (
                        randN(
                            tokenHash,
                            string(abi.encodePacked("vertOppScale2", attemptNum, depth)  ),
                            0,
                            100
                        ) > 50
                    ) {
                        scale = 1000; /// desired = 1 (same scale)
                    } else {
                        scale = 500; /// desired = 0.5 (half scale)
                    }
                } else {
                    scale = 2000; /// desired = 2 (double scale)
                }
            } else {
                scale = overrideScale;
            }
        } else {
            scale = 1e3;
        }

        /// make a new triangle
        int256[3][3] memory newTri = makeTriVertOpp(
            triVars.tris[refIdx],
            geomSpec,
            sideIdx,
            scale
        );

        /// set the zbackref and frontbackref
        triVars.zBackRef = -1; /// calculate a new z back
        triVars.zFrontRef = triVars.zFronts[refIdx];

        // try to add the triangle, and use the reference z height
        triVars.recursiveAttempt = false;
        bool wasAdded = attemptToAddTri(newTri, tokenHash, triVars, geomSpec);

        if (wasAdded) {
            /// run again
            if (
                randN(
                    tokenHash,
                    string(
                        abi.encodePacked("recursiveVertOpp", attemptNum, depth)
                    ),
                    0,
                    100
                ) <= geomSpec.probVertOppRec
            ) {
                triVars = makeVerticallyOppositeTriangles(
                    tokenHash,
                    attemptNum,
                    refIdx,
                    triVars,
                    geomSpec,
                    sideIdx,
                    666, /// always make the next one 2/3 scale
                    depth + 1
                );
            }
        }

        return triVars;
    }

    /** @dev place a triangle vertically opposite over the given point 
    @param refTri the reference triangle to base the new triangle on
    */
    function makeTriVertOpp(
        int256[3][3] memory refTri,
        GeomSpec memory geomSpec,
        int256 sideIdx,
        int256 scale
    ) internal view returns (int256[3][3] memory) {
        /// calculate the center of the reference triangle
        /// add and then divide by 1e3 (the factor by which scale is scaled up)
        int256 centerDist = (getRadiusLen(refTri) * (1e3 + scale)) / 1e3;

        /// get the new triangle's direction
        int256 newAngle = sideIdx *
            120 +
            60 +
            (isTriPointingUp(refTri) ? int256(60) : int256(0));

        int256 spacing = 64;

        /// calculate the true offset
        int256[3] memory offset = vector3RotateZ(
            [int256(0), centerDist + spacing, 0],
            newAngle
        );

        int256[3] memory centerVec = getCenterVec(refTri);
        int256[3] memory newCentre = ShackledMath.vector3Add(centerVec, offset);
        /// return the new triangle (div by 1e3 to account for scale)
        int256 newRadius = (scale * getRadiusLen(refTri)) / 1e3;
        newRadius = ShackledMath.min(geomSpec.maxTriRad, newRadius);
        newAngle -= 210;
        return makeTri(newCentre, newRadius, newAngle);
    }

    /** @dev make a new adjacent triangle
     */
    function makeTriAdjacent(
        bytes32 tokenHash,
        GeomSpec memory geomSpec,
        uint256 attemptNum,
        int256[3][3] memory refTri,
        int256 sideIdx,
        int256 scale,
        int256 depth
    ) internal view returns (int256[3][3] memory) {
        /// calculate the center of the new triangle
        /// add and then divide by 1e3 (the factor by which scale is scaled up)

        int256 centerDist = (getPerpLen(refTri) * (1e3 + scale)) / 1e3;

        /// get the new triangle's direction
        int256 newAngle = sideIdx *
            120 +
            (isTriPointingUp(refTri) ? int256(60) : int256(0));

        /// determine the direction of the offset offset
        /// get a unique random seed each attempt to ensure variation

        // prettier-ignore
        int256 offsetDirection = randN(
            tokenHash,
            string(abi.encodePacked("lateralOffset", attemptNum, depth)),
            0, 
            1
        ) 
        * 2 - 1;

        /// put if off to one side of the triangle if it's smaller
        /// scale is on order of 1e3
        int256 lateralOffset = (offsetDirection *
            (1e3 - scale) *
            getSideLen(refTri)) / 1e3;

        /// make a gap between the triangles
        int256 spacing = 6000;

        /// calculate the true offset
        int256[3] memory offset = vector3RotateZ(
            [lateralOffset, centerDist + spacing, 0],
            newAngle
        );

        int256[3] memory newCentre = ShackledMath.vector3Add(
            getCenterVec(refTri),
            offset
        );

        /// return the new triangle (div by 1e3 to account for scale)
        int256 newRadius = (scale * getRadiusLen(refTri)) / 1e3;
        newRadius = ShackledMath.min(geomSpec.maxTriRad, newRadius);
        newAngle -= 30;
        return makeTri(newCentre, newRadius, newAngle);
    }

    /** @dev  
    create a triangle centered at centre, 
    with length from centre to point of radius
    */
    function makeTri(
        int256[3] memory centre,
        int256 radius,
        int256 angle
    ) internal view returns (int256[3][3] memory tri) {
        /// create a vector to rotate around 3 times
        int256[3] memory offset = [radius, 0, 0];

        /// make 3 points of the tri
        for (uint256 i = 0; i < 3; i++) {
            int256 armAngle = 120 * int256(i);
            int256[3] memory offsetVec = vector3RotateZ(
                offset,
                armAngle + angle
            );

            tri[i] = ShackledMath.vector3Add(centre, offsetVec);
        }
    }

    /** @dev rotate a vector around x */
    function vector3RotateX(int256[3] memory v, int256 deg)
        internal
        view
        returns (int256[3] memory)
    {
        /// get the cos and sin of the angle
        (int256 cos, int256 sin) = trigHelper(deg);

        /// calculate new y and z (scaling down to account for trig scaling)
        int256 y = ((v[1] * cos) - (v[2] * sin)) / 1e18;
        int256 z = ((v[1] * sin) + (v[2] * cos)) / 1e18;
        return [v[0], y, z];
    }

    /** @dev rotate a vector around y */
    function vector3RotateY(int256[3] memory v, int256 deg)
        internal
        view
        returns (int256[3] memory)
    {
        /// get the cos and sin of the angle
        (int256 cos, int256 sin) = trigHelper(deg);

        /// calculate new x and z (scaling down to account for trig scaling)
        int256 x = ((v[0] * cos) - (v[2] * sin)) / 1e18;
        int256 z = ((v[0] * sin) + (v[2] * cos)) / 1e18;
        return [x, v[1], z];
    }

    /** @dev rotate a vector around z */
    function vector3RotateZ(int256[3] memory v, int256 deg)
        internal
        view
        returns (int256[3] memory)
    {
        /// get the cos and sin of the angle
        (int256 cos, int256 sin) = trigHelper(deg);

        /// calculate new x and y (scaling down to account for trig scaling)
        int256 x = ((v[0] * cos) - (v[1] * sin)) / 1e18;
        int256 y = ((v[0] * sin) + (v[1] * cos)) / 1e18;
        return [x, y, v[2]];
    }

    /** @dev calculate sin and cos of an angle */
    function trigHelper(int256 deg)
        internal
        view
        returns (int256 cos, int256 sin)
    {
        /// deal with negative degrees here, since Trigonometry.sol can't
        int256 n360 = (ShackledMath.abs(deg) / 360) + 1;
        deg = (deg + (360 * n360)) % 360;
        uint256 rads = uint256((deg * PI) / 180);
        /// calculate radians (in 1e18 space)
        cos = Trigonometry.cos(rads);
        sin = Trigonometry.sin(rads);
    }

    /** @dev Get the 3d vector at the center of a triangle */
    function getCenterVec(int256[3][3] memory tri)
        internal
        view
        returns (int256[3] memory)
    {
        return
            ShackledMath.vector3DivScalar(
                ShackledMath.vector3Add(
                    ShackledMath.vector3Add(tri[0], tri[1]),
                    tri[2]
                ),
                3
            );
    }

    /** @dev Get the length from the center of a triangle to point*/
    function getRadiusLen(int256[3][3] memory tri)
        internal
        view
        returns (int256)
    {
        return
            ShackledMath.vector3Len(
                ShackledMath.vector3Sub(getCenterVec(tri), tri[0])
            );
    }

    /** @dev Get the length from any point on triangle to other point (equilateral)*/
    function getSideLen(int256[3][3] memory tri)
        internal
        view
        returns (int256)
    {
        // len * 0.886
        return (getRadiusLen(tri) * 8660) / 10000;
    }

    /** @dev Get the shortes length from center of triangle to side */
    function getPerpLen(int256[3][3] memory tri)
        internal
        view
        returns (int256)
    {
        return getRadiusLen(tri) / 2;
    }

    /** @dev Determine if a triangle is pointing up*/
    function isTriPointingUp(int256[3][3] memory tri)
        internal
        view
        returns (bool)
    {
        int256 centerY = getCenterVec(tri)[1];
        /// count how many verts are above this y value
        int256 nAbove = 0;
        for (uint256 i = 0; i < 3; i++) {
            if (tri[i][1] > centerY) {
                nAbove++;
            }
        }
        return nAbove == 1;
    }

    /** @dev check if two triangles are close */
    function areTrisClose(int256[3][3] memory tri1, int256[3][3] memory tri2)
        internal
        view
        returns (bool)
    {
        int256 lenBetweenCenters = ShackledMath.vector3Len(
            ShackledMath.vector3Sub(getCenterVec(tri1), getCenterVec(tri2))
        );
        return lenBetweenCenters < (getPerpLen(tri1) + getPerpLen(tri2));
    }

    /** @dev check if two triangles have overlapping points*/
    function areTrisPointsOverlapping(
        int256[3][3] memory tri1,
        int256[3][3] memory tri2
    ) internal view returns (bool) {
        /// check triangle a against b
        if (
            isPointInTri(tri1, tri2[0]) ||
            isPointInTri(tri1, tri2[1]) ||
            isPointInTri(tri1, tri2[2])
        ) {
            return true;
        }

        /// check triangle b against a
        if (
            isPointInTri(tri2, tri1[0]) ||
            isPointInTri(tri2, tri1[1]) ||
            isPointInTri(tri2, tri1[2])
        ) {
            return true;
        }

        /// otherwise they mustn't be overlapping
        return false;
    }

    /** @dev calculate if a point is in a tri*/
    function isPointInTri(int256[3][3] memory tri, int256[3] memory p)
        internal
        view
        returns (bool)
    {
        int256[3] memory p1 = tri[0];
        int256[3] memory p2 = tri[1];
        int256[3] memory p3 = tri[2];
        int256 alphaNum = (p2[1] - p3[1]) *
            (p[0] - p3[0]) +
            (p3[0] - p2[0]) *
            (p[1] - p3[1]);

        int256 alphaDenom = (p2[1] - p3[1]) *
            (p1[0] - p3[0]) +
            (p3[0] - p2[0]) *
            (p1[1] - p3[1]);

        int256 betaNum = (p3[1] - p1[1]) *
            (p[0] - p3[0]) +
            (p1[0] - p3[0]) *
            (p[1] - p3[1]);

        int256 betaDenom = (p2[1] - p3[1]) *
            (p1[0] - p3[0]) +
            (p3[0] - p2[0]) *
            (p1[1] - p3[1]);

        if (alphaDenom == 0 || betaDenom == 0) {
            return false;
        } else {
            int256 alpha = (alphaNum * 1e6) / alphaDenom;
            int256 beta = (betaNum * 1e6) / betaDenom;

            int256 gamma = 1e6 - alpha - beta;
            return alpha > 0 && beta > 0 && gamma > 0;
        }
    }

    /** @dev check all points of the tri to see if it overlaps with any other tris
     */
    function isTriOverlappingWithTris(
        int256[3][3] memory tri,
        int256[3][3][] memory tris,
        uint256 nextTriIdx
    ) internal view returns (bool) {
        /// check against all other tris added thus fat
        for (uint256 i = 0; i < nextTriIdx; i++) {
            if (
                areTrisClose(tri, tris[i]) ||
                areTrisPointsOverlapping(tri, tris[i])
            ) {
                return true;
            }
        }
        return false;
    }

    function isPointCloseToLine(
        int256[3] memory p,
        int256[3] memory l1,
        int256[3] memory l2
    ) internal view returns (bool) {
        int256 x0 = p[0];
        int256 y0 = p[1];
        int256 x1 = l1[0];
        int256 y1 = l1[1];
        int256 x2 = l2[0];
        int256 y2 = l2[1];
        int256 distanceNum = ShackledMath.abs(
            (x2 - x1) * (y1 - y0) - (x1 - x0) * (y2 - y1)
        );
        int256 distanceDenom = ShackledMath.hypot((x2 - x1), (y2 - y1));
        int256 distance = distanceNum / distanceDenom;
        if (distance < 8) {
            return true;
        }
    }

    /** compare a triangles points against the lines of other tris */
    function isTrisPointsCloseToLines(
        int256[3][3] memory tri,
        int256[3][3][] memory tris,
        uint256 nextTriIdx
    ) internal view returns (bool) {
        for (uint256 i = 0; i < nextTriIdx; i++) {
            for (uint256 p = 0; p < 3; p++) {
                if (isPointCloseToLine(tri[p], tris[i][0], tris[i][1])) {
                    return true;
                }
                if (isPointCloseToLine(tri[p], tris[i][1], tris[i][2])) {
                    return true;
                }
                if (isPointCloseToLine(tri[p], tris[i][2], tris[i][0])) {
                    return true;
                }
            }
        }
    }

    /** @dev check if tri to add meets certain criteria */
    function isTriLegal(
        int256[3][3] memory tri,
        int256[3][3][] memory tris,
        uint256 nextTriIdx,
        int256 minTriRad
    ) internal view returns (bool) {
        // check radius first as point checks will fail
        // if the radius is too small
        if (getRadiusLen(tri) < minTriRad) {
            return false;
        }
        return (!isTriOverlappingWithTris(tri, tris, nextTriIdx) &&
            !isTrisPointsCloseToLines(tri, tris, nextTriIdx));
    }

    /** @dev helper function to add triangles */
    function attemptToAddTri(
        int256[3][3] memory tri,
        bytes32 tokenHash,
        TriVars memory triVars,
        GeomSpec memory geomSpec
    ) internal view returns (bool added) {
        bool isLegal = isTriLegal(
            tri,
            triVars.tris,
            triVars.nextTriIdx,
            geomSpec.minTriRad
        );
        if (isLegal && triVars.nextTriIdx < geomSpec.maxPrisms) {
            // add the triangle
            triVars.tris[triVars.nextTriIdx] = tri;
            added = true;

            // add the new zs
            if (triVars.zBackRef == -1) {
                /// z back ref is not provided, calculate it
                triVars.zBacks[triVars.nextTriIdx] = calculateZ(
                    tri,
                    tokenHash,
                    triVars.nextTriIdx,
                    geomSpec,
                    false
                );
            } else {
                /// use the provided z back (from the ref)
                triVars.zBacks[triVars.nextTriIdx] = triVars.zBackRef;
            }
            if (triVars.zFrontRef == -1) {
                /// z front ref is not provided, calculate it
                triVars.zFronts[triVars.nextTriIdx] = calculateZ(
                    tri,
                    tokenHash,
                    triVars.nextTriIdx,
                    geomSpec,
                    true
                );
            } else {
                /// use the provided z front (from the ref)
                triVars.zFronts[triVars.nextTriIdx] = triVars.zFrontRef;
            }

            // increment the tris counter
            triVars.nextTriIdx += 1;

            // if we're using any type of symmetry then attempt to add a symmetric triangle
            // only do this recursively once
            if (
                (geomSpec.isSymmetricX || geomSpec.isSymmetricY) &&
                (!triVars.recursiveAttempt)
            ) {
                int256[3][3] memory symTri = copyTri(tri);

                if (geomSpec.isSymmetricX) {
                    symTri[0][0] = -symTri[0][0];
                    symTri[1][0] = -symTri[1][0];
                    symTri[2][0] = -symTri[2][0];
                    // symCenter[0] = -symCenter[0];
                }

                if (geomSpec.isSymmetricY) {
                    symTri[0][1] = -symTri[0][1];
                    symTri[1][1] = -symTri[1][1];
                    symTri[2][1] = -symTri[2][1];
                    // symCenter[1] = -symCenter[1];
                }

                if (
                    (geomSpec.isSymmetricX || geomSpec.isSymmetricY) &&
                    !(geomSpec.isSymmetricX && geomSpec.isSymmetricY)
                ) {
                    symTri = [symTri[2], symTri[1], symTri[0]];
                }

                triVars.recursiveAttempt = true;
                triVars.zBackRef = triVars.zBacks[triVars.nextTriIdx - 1];
                triVars.zFrontRef = triVars.zFronts[triVars.nextTriIdx - 1];
                attemptToAddTri(symTri, tokenHash, triVars, geomSpec);
            }
        }
    }

    /** @dev rotate a triangle by x, y, or z 
    @param axis 0 = x, 1 = y, 2 = z
    */
    function triRotHelp(
        int256 axis,
        int256[3][3] memory tri,
        int256 rot
    ) internal view returns (int256[3][3] memory) {
        if (axis == 0) {
            return [
                vector3RotateX(tri[0], rot),
                vector3RotateX(tri[1], rot),
                vector3RotateX(tri[2], rot)
            ];
        } else if (axis == 1) {
            return [
                vector3RotateY(tri[0], rot),
                vector3RotateY(tri[1], rot),
                vector3RotateY(tri[2], rot)
            ];
        } else if (axis == 2) {
            return [
                vector3RotateZ(tri[0], rot),
                vector3RotateZ(tri[1], rot),
                vector3RotateZ(tri[2], rot)
            ];
        }
    }

    /** @dev a helper to run rotation functions on back/front triangles */
    function triBfHelp(
        int256 axis,
        int256[3][3][] memory trisBack,
        int256[3][3][] memory trisFront,
        int256 rot
    ) internal view returns (int256[3][3][] memory, int256[3][3][] memory) {
        int256[3][3][] memory trisBackNew = new int256[3][3][](trisBack.length);
        int256[3][3][] memory trisFrontNew = new int256[3][3][](
            trisFront.length
        );

        for (uint256 i = 0; i < trisBack.length; i++) {
            trisBackNew[i] = triRotHelp(axis, trisBack[i], rot);
            trisFrontNew[i] = triRotHelp(axis, trisFront[i], rot);
        }

        return (trisBackNew, trisFrontNew);
    }

    /** @dev get the maximum extent of the geometry (vertical or horizontal) */
    function getExtents(int256[3][3][] memory tris)
        internal
        view
        returns (int256[3][2] memory)
    {
        int256 minX = MAX_INT;
        int256 maxX = MIN_INT;
        int256 minY = MAX_INT;
        int256 maxY = MIN_INT;
        int256 minZ = MAX_INT;
        int256 maxZ = MIN_INT;

        for (uint256 i = 0; i < tris.length; i++) {
            for (uint256 j = 0; j < tris[i].length; j++) {
                minX = ShackledMath.min(minX, tris[i][j][0]);
                maxX = ShackledMath.max(maxX, tris[i][j][0]);
                minY = ShackledMath.min(minY, tris[i][j][1]);
                maxY = ShackledMath.max(maxY, tris[i][j][1]);
                minZ = ShackledMath.min(minZ, tris[i][j][2]);
                maxZ = ShackledMath.max(maxZ, tris[i][j][2]);
            }
        }
        return [[minX, minY, minZ], [maxX, maxY, maxZ]];
    }

    /** @dev go through each triangle and apply a 'height' */
    function calculateZ(
        int256[3][3] memory tri,
        bytes32 tokenHash,
        uint256 nextTriIdx,
        GeomSpec memory geomSpec,
        bool front
    ) internal view returns (int256) {
        int256 h;
        string memory seedMod = string(abi.encodePacked("calcZ", nextTriIdx));
        if (front) {
            if (geomSpec.id == 6) {
                h = 1;
            } else {
                if (randN(tokenHash, seedMod, 0, 10) > 9) {
                    if (randN(tokenHash, seedMod, 0, 10) > 3) {
                        h = 10;
                    } else {
                        h = 22;
                    }
                } else {
                    if (randN(tokenHash, seedMod, 0, 10) > 5) {
                        h = 8;
                    } else {
                        h = 1;
                    }
                }
            }
        } else {
            if (geomSpec.id == 6) {
                h = -1;
            } else {
                if (geomSpec.id == 5) {
                    h = -randN(tokenHash, seedMod, 2, 20);
                } else {
                    h = -2;
                }
            }
        }
        if (geomSpec.id == 5) {
            h += 10;
        }
        return h * geomSpec.depthMultiplier;
    }

    /** @dev roll a specId given a list of weightings */
    function getSpecId(bytes32 tokenHash, int256[2][7] memory weightings)
        internal
        view
        returns (uint256)
    {
        int256 n = GeomUtils.randN(
            tokenHash,
            "specId",
            weightings[0][0],
            weightings[weightings.length - 1][1]
        );
        for (uint256 i = 0; i < weightings.length; i++) {
            if (weightings[i][0] <= n && n <= weightings[i][1]) {
                return i;
            }
        }
    }

    /** @dev get a random number between two numbers
    with a uniform probability distribution
    @param randomSeed a hash that we can use to 'randomly' get a number 
    @param seedModifier some string to make the result unique for this tokenHash
    @param min the minimum number (inclusive)
    @param max the maximum number (inclusive)

    examples:
        to get binary output (0 or 1), set min as 0 and max as 1
        
     */
    function randN(
        bytes32 randomSeed,
        string memory seedModifier,
        int256 min,
        int256 max
    ) internal view returns (int256) {
        /// use max() to ensure modulo != 0
        return
            int256(
                uint256(keccak256(abi.encodePacked(randomSeed, seedModifier))) %
                    uint256(ShackledMath.max(1, (max + 1 - min)))
            ) + min;
    }

    /** @dev clip an array of tris to a certain length (to trim empty tail slots) */
    function clipTrisToLength(int256[3][3][] memory arr, uint256 desiredLen)
        internal
        view
        returns (int256[3][3][] memory)
    {
        uint256 n = arr.length - desiredLen;
        assembly {
            mstore(arr, sub(mload(arr), n))
        }
        return arr;
    }

    /** @dev clip an array of Z values to a certain length (to trim empty tail slots) */
    function clipZsToLength(int256[] memory arr, uint256 desiredLen)
        internal
        view
        returns (int256[] memory)
    {
        uint256 n = arr.length - desiredLen;
        assembly {
            mstore(arr, sub(mload(arr), n))
        }
        return arr;
    }

    /** @dev make a copy of a triangle */
    function copyTri(int256[3][3] memory tri)
        internal
        view
        returns (int256[3][3] memory)
    {
        return [
            [tri[0][0], tri[0][1], tri[0][2]],
            [tri[1][0], tri[1][1], tri[1][2]],
            [tri[2][0], tri[2][1], tri[2][2]]
        ];
    }

    /** @dev make a copy of an array of triangles */
    function copyTris(int256[3][3][] memory tris)
        internal
        view
        returns (int256[3][3][] memory)
    {
        int256[3][3][] memory newTris = new int256[3][3][](tris.length);
        for (uint256 i = 0; i < tris.length; i++) {
            newTris[i] = copyTri(tris[i]);
        }
        return newTris;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

library ShackledStructs {
    struct Metadata {
        string colorScheme; /// name of the color scheme
        string geomSpec; /// name of the geometry specification
        uint256 nPrisms; /// number of prisms made
        string pseudoSymmetry; /// horizontal, vertical, diagonal
        string wireframe; /// enabled or disabled
        string inversion; /// enabled or disabled
    }

    struct RenderParams {
        uint256[3][] faces; /// index of verts and colorss used for each face (triangle)
        int256[3][] verts; /// x, y, z coordinates used in the geometry
        int256[3][] cols; /// colors of each vert
        int256[3] objPosition; /// position to place the object
        int256 objScale; /// scalar for the object
        int256[3][2] backgroundColor; /// color of the background (gradient)
        LightingParams lightingParams; /// parameters for the lighting
        bool perspCamera; /// true = perspective camera, false = orthographic
        bool backfaceCulling; /// whether to implement backface culling (saves gas!)
        bool invert; /// whether to invert colors in the final encoding stage
        bool wireframe; /// whether to only render edges
    }

    /// struct for testing lighting
    struct LightingParams {
        bool applyLighting; /// true = apply lighting, false = don't apply lighting
        int256 lightAmbiPower; /// power of the ambient light
        int256 lightDiffPower; /// power of the diffuse light
        int256 lightSpecPower; /// power of the specular light
        uint256 inverseShininess; /// shininess of the material
        int256[3] lightPos; /// position of the light
        int256[3] lightColSpec; /// color of the specular light
        int256[3] lightColDiff; /// color of the diffuse light
        int256[3] lightColAmbi; /// color of the ambient light
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library ShackledMath {
    /** @dev Get the minimum of two numbers */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /** @dev Get the maximum of two numbers */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /** @dev perform a modulo operation, with support for negative numbers */
    function mod(int256 n, int256 m) internal pure returns (int256) {
        if (n < 0) {
            return ((n % m) + m) % m;
        } else {
            return n % m;
        }
    }

    /** @dev 'randomly' select n numbers between 0 and m 
    (useful for getting a randomly sampled index)
    */
    function randomIdx(
        bytes32 seedModifier,
        uint256 n, // number of elements to select
        uint256 m // max value of elements
    ) internal pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            result[i] =
                uint256(keccak256(abi.encodePacked(seedModifier, i))) %
                m;
        }
        return result;
    }

    /** @dev create a 2d array and fill with a single value */
    function get2dArray(
        uint256 m,
        uint256 q,
        int256 value
    ) internal pure returns (int256[][] memory) {
        /// Create a matrix of values with dimensions (m, q)
        int256[][] memory rows = new int256[][](m);
        for (uint256 i = 0; i < m; i++) {
            int256[] memory row = new int256[](q);
            for (uint256 j = 0; j < q; j++) {
                row[j] = value;
            }
            rows[i] = row;
        }
        return rows;
    }

    /** @dev get the absolute of a number
     */
    function abs(int256 x) internal pure returns (int256) {
        assembly {
            if slt(x, 0) {
                x := sub(0, x)
            }
        }
        return x;
    }

    /** @dev get the square root of a number
     */
    function sqrt(int256 y) internal pure returns (int256 z) {
        assembly {
            if sgt(y, 3) {
                z := y
                let x := add(div(y, 2), 1)
                for {

                } slt(x, z) {

                } {
                    z := x
                    x := div(add(div(y, x), x), 2)
                }
            }
            if and(slt(y, 4), sgt(y, 0)) {
                z := 1
            }
        }
    }

    /** @dev get the hypotenuse of a triangle given the length of 2 sides
     */
    function hypot(int256 x, int256 y) internal pure returns (int256) {
        int256 sumsq;
        assembly {
            let xsq := mul(x, x)
            let ysq := mul(y, y)
            sumsq := add(xsq, ysq)
        }

        return sqrt(sumsq);
    }

    /** @dev addition between two vectors (size 3)
     */
    function vector3Add(int256[3] memory v1, int256[3] memory v2)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(result, add(mload(v1), mload(v2)))
            mstore(
                add(result, 0x20),
                add(mload(add(v1, 0x20)), mload(add(v2, 0x20)))
            )
            mstore(
                add(result, 0x40),
                add(mload(add(v1, 0x40)), mload(add(v2, 0x40)))
            )
        }
    }

    /** @dev subtraction between two vectors (size 3)
     */
    function vector3Sub(int256[3] memory v1, int256[3] memory v2)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(result, sub(mload(v1), mload(v2)))
            mstore(
                add(result, 0x20),
                sub(mload(add(v1, 0x20)), mload(add(v2, 0x20)))
            )
            mstore(
                add(result, 0x40),
                sub(mload(add(v1, 0x40)), mload(add(v2, 0x40)))
            )
        }
    }

    /** @dev multiply a vector (size 3) by a constant
     */
    function vector3MulScalar(int256[3] memory v, int256 a)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(result, mul(mload(v), a))
            mstore(add(result, 0x20), mul(mload(add(v, 0x20)), a))
            mstore(add(result, 0x40), mul(mload(add(v, 0x40)), a))
        }
    }

    /** @dev divide a vector (size 3) by a constant
     */
    function vector3DivScalar(int256[3] memory v, int256 a)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(result, sdiv(mload(v), a))
            mstore(add(result, 0x20), sdiv(mload(add(v, 0x20)), a))
            mstore(add(result, 0x40), sdiv(mload(add(v, 0x40)), a))
        }
    }

    /** @dev get the length of a vector (size 3)
     */
    function vector3Len(int256[3] memory v) internal pure returns (int256) {
        int256 res;
        assembly {
            let x := mload(v)
            let y := mload(add(v, 0x20))
            let z := mload(add(v, 0x40))
            res := add(add(mul(x, x), mul(y, y)), mul(z, z))
        }
        return sqrt(res);
    }

    /** @dev scale and then normalise a vector (size 3)
     */
    function vector3NormX(int256[3] memory v, int256 fidelity)
        internal
        pure
        returns (int256[3] memory result)
    {
        int256 l = vector3Len(v);
        assembly {
            mstore(result, sdiv(mul(fidelity, mload(add(v, 0x40))), l))
            mstore(
                add(result, 0x20),
                sdiv(mul(fidelity, mload(add(v, 0x20))), l)
            )
            mstore(add(result, 0x40), sdiv(mul(fidelity, mload(v)), l))
        }
    }

    /** @dev get the dot-product of two vectors (size 3)
     */
    function vector3Dot(int256[3] memory v1, int256[3] memory v2)
        internal
        view
        returns (int256 result)
    {
        assembly {
            result := add(
                add(
                    mul(mload(v1), mload(v2)),
                    mul(mload(add(v1, 0x20)), mload(add(v2, 0x20)))
                ),
                mul(mload(add(v1, 0x40)), mload(add(v2, 0x40)))
            )
        }
    }

    /** @dev get the cross product of two vectors (size 3)
     */
    function crossProduct(int256[3] memory v1, int256[3] memory v2)
        internal
        pure
        returns (int256[3] memory result)
    {
        assembly {
            mstore(
                result,
                sub(
                    mul(mload(add(v1, 0x20)), mload(add(v2, 0x40))),
                    mul(mload(add(v1, 0x40)), mload(add(v2, 0x20)))
                )
            )
            mstore(
                add(result, 0x20),
                sub(
                    mul(mload(add(v1, 0x40)), mload(v2)),
                    mul(mload(v1), mload(add(v2, 0x40)))
                )
            )
            mstore(
                add(result, 0x40),
                sub(
                    mul(mload(v1), mload(add(v2, 0x20))),
                    mul(mload(add(v1, 0x20)), mload(v2))
                )
            )
        }
    }

    /** @dev linearly interpolate between two vectors (size 12)
     */
    function vector12Lerp(
        int256[12] memory v1,
        int256[12] memory v2,
        int256 ir,
        int256 scaleFactor
    ) internal view returns (int256[12] memory result) {
        int256[12] memory vd = vector12Sub(v2, v1);
        // loop through all 12 items
        assembly {
            let ix
            for {
                let i := 0
            } lt(i, 0xC) {
                // (i < 12)
                i := add(i, 1)
            } {
                /// get index of the next element
                ix := mul(i, 0x20)

                /// store into the result array
                mstore(
                    add(result, ix),
                    add(
                        // v1[i] + (ir * vd[i]) / 1e3
                        mload(add(v1, ix)),
                        sdiv(mul(ir, mload(add(vd, ix))), 1000)
                    )
                )
            }
        }
    }

    /** @dev subtraction between two vectors (size 12)
     */
    function vector12Sub(int256[12] memory v1, int256[12] memory v2)
        internal
        view
        returns (int256[12] memory result)
    {
        // loop through all 12 items
        assembly {
            let ix
            for {
                let i := 0
            } lt(i, 0xC) {
                // (i < 12)
                i := add(i, 1)
            } {
                /// get index of the next element
                ix := mul(i, 0x20)
                /// store into the result array
                mstore(
                    add(result, ix),
                    sub(
                        // v1[ix] - v2[ix]
                        mload(add(v1, ix)),
                        mload(add(v2, ix))
                    )
                )
            }
        }
    }

    /** @dev map a number from one range into another
     */
    function mapRangeToRange(
        int256 num,
        int256 inMin,
        int256 inMax,
        int256 outMin,
        int256 outMax
    ) internal pure returns (int256 res) {
        assembly {
            res := add(
                sdiv(
                    mul(sub(outMax, outMin), sub(num, inMin)),
                    sub(inMax, inMin)
                ),
                outMin
            )
        }
    }
}

// SPDX-License-Identifier: MIT
/**
 * @notice Solidity library offering basic trigonometry functions where inputs and outputs are
 * integers. Inputs are specified in radians scaled by 1e18, and similarly outputs are scaled by 1e18.
 *
 * This implementation is based off the Solidity trigonometry library written by Lefteris Karapetsas
 * which can be found here: https://github.com/Sikorkaio/sikorka/blob/e75c91925c914beaedf4841c0336a806f2b5f66d/contracts/trigonometry.sol
 *
 * Compared to Lefteris' implementation, this version makes the following changes:
 *   - Uses a 32 bits instead of 16 bits for improved accuracy
 *   - Updated for Solidity 0.8.x
 *   - Various gas optimizations
 *   - Change inputs/outputs to standard trig format (scaled by 1e18) instead of requiring the
 *     integer format used by the algorithm
 *
 * Lefertis' implementation is based off Dave Dribin's trigint C library
 *     http://www.dribin.org/dave/trigint/
 *
 * Which in turn is based from a now deleted article which can be found in the Wayback Machine:
 *     http://web.archive.org/web/20120301144605/http://www.dattalo.com/technical/software/pic/picsine.html
 */

pragma solidity ^0.8.0;

library Trigonometry {
    // Table index into the trigonometric table
    uint256 constant INDEX_WIDTH = 8;
    // Interpolation between successive entries in the table
    uint256 constant INTERP_WIDTH = 16;
    uint256 constant INDEX_OFFSET = 28 - INDEX_WIDTH;
    uint256 constant INTERP_OFFSET = INDEX_OFFSET - INTERP_WIDTH;
    uint32 constant ANGLES_IN_CYCLE = 1073741824;
    uint32 constant QUADRANT_HIGH_MASK = 536870912;
    uint32 constant QUADRANT_LOW_MASK = 268435456;
    uint256 constant SINE_TABLE_SIZE = 256;

    // Pi as an 18 decimal value, which is plenty of accuracy: "For JPL's highest accuracy calculations, which are for
    // interplanetary navigation, we use 3.141592653589793: https://www.jpl.nasa.gov/edu/news/2016/3/16/how-many-decimals-of-pi-do-we-really-need/
    uint256 constant PI = 3141592653589793238;
    uint256 constant TWO_PI = 2 * PI;
    uint256 constant PI_OVER_TWO = PI / 2;

    // The constant sine lookup table was generated by generate_trigonometry.py. We must use a constant
    // bytes array because constant arrays are not supported in Solidity. Each entry in the lookup
    // table is 4 bytes. Since we're using 32-bit parameters for the lookup table, we get a table size
    // of 2^(32/4) + 1 = 257, where the first and last entries are equivalent (hence the table size of
    // 256 defined above)
    uint8 constant entry_bytes = 4; // each entry in the lookup table is 4 bytes
    uint256 constant entry_mask = ((1 << (8 * entry_bytes)) - 1); // mask used to cast bytes32 -> lookup table entry
    bytes constant sin_table =
        hex"00_00_00_00_00_c9_0f_88_01_92_1d_20_02_5b_26_d7_03_24_2a_bf_03_ed_26_e6_04_b6_19_5d_05_7f_00_35_06_47_d9_7c_07_10_a3_45_07_d9_5b_9e_08_a2_00_9a_09_6a_90_49_0a_33_08_bc_0a_fb_68_05_0b_c3_ac_35_0c_8b_d3_5e_0d_53_db_92_0e_1b_c2_e4_0e_e3_87_66_0f_ab_27_2b_10_72_a0_48_11_39_f0_cf_12_01_16_d5_12_c8_10_6e_13_8e_db_b1_14_55_76_b1_15_1b_df_85_15_e2_14_44_16_a8_13_05_17_6d_d9_de_18_33_66_e8_18_f8_b8_3c_19_bd_cb_f3_1a_82_a0_25_1b_47_32_ef_1c_0b_82_6a_1c_cf_8c_b3_1d_93_4f_e5_1e_56_ca_1e_1f_19_f9_7b_1f_dc_dc_1b_20_9f_70_1c_21_61_b3_9f_22_23_a4_c5_22_e5_41_af_23_a6_88_7e_24_67_77_57_25_28_0c_5d_25_e8_45_b6_26_a8_21_85_27_67_9d_f4_28_26_b9_28_28_e5_71_4a_29_a3_c4_85_2a_61_b1_01_2b_1f_34_eb_2b_dc_4e_6f_2c_98_fb_ba_2d_55_3a_fb_2e_11_0a_62_2e_cc_68_1e_2f_87_52_62_30_41_c7_60_30_fb_c5_4d_31_b5_4a_5d_32_6e_54_c7_33_26_e2_c2_33_de_f2_87_34_96_82_4f_35_4d_90_56_36_04_1a_d9_36_ba_20_13_37_6f_9e_46_38_24_93_b0_38_d8_fe_93_39_8c_dd_32_3a_40_2d_d1_3a_f2_ee_b7_3b_a5_1e_29_3c_56_ba_70_3d_07_c1_d5_3d_b8_32_a5_3e_68_0b_2c_3f_17_49_b7_3f_c5_ec_97_40_73_f2_1d_41_21_58_9a_41_ce_1e_64_42_7a_41_d0_43_25_c1_35_43_d0_9a_ec_44_7a_cd_50_45_24_56_bc_45_cd_35_8f_46_75_68_27_47_1c_ec_e6_47_c3_c2_2e_48_69_e6_64_49_0f_57_ee_49_b4_15_33_4a_58_1c_9d_4a_fb_6c_97_4b_9e_03_8f_4c_3f_df_f3_4c_e1_00_34_4d_81_62_c3_4e_21_06_17_4e_bf_e8_a4_4f_5e_08_e2_4f_fb_65_4c_50_97_fc_5e_51_33_cc_94_51_ce_d4_6e_52_69_12_6e_53_02_85_17_53_9b_2a_ef_54_33_02_7d_54_ca_0a_4a_55_60_40_e2_55_f5_a4_d2_56_8a_34_a9_57_1d_ee_f9_57_b0_d2_55_58_42_dd_54_58_d4_0e_8c_59_64_64_97_59_f3_de_12_5a_82_79_99_5b_10_35_ce_5b_9d_11_53_5c_29_0a_cc_5c_b4_20_df_5d_3e_52_36_5d_c7_9d_7b_5e_50_01_5d_5e_d7_7c_89_5f_5e_0d_b2_5f_e3_b3_8d_60_68_6c_ce_60_ec_38_2f_61_6f_14_6b_61_f1_00_3e_62_71_fa_68_62_f2_01_ac_63_71_14_cc_63_ef_32_8f_64_6c_59_bf_64_e8_89_25_65_63_bf_91_65_dd_fb_d2_66_57_3c_bb_66_cf_81_1f_67_46_c7_d7_67_bd_0f_bc_68_32_57_aa_68_a6_9e_80_69_19_e3_1f_69_8c_24_6b_69_fd_61_4a_6a_6d_98_a3_6a_dc_c9_64_6b_4a_f2_78_6b_b8_12_d0_6c_24_29_5f_6c_8f_35_1b_6c_f9_34_fb_6d_62_27_f9_6d_ca_0d_14_6e_30_e3_49_6e_96_a9_9c_6e_fb_5f_11_6f_5f_02_b1_6f_c1_93_84_70_23_10_99_70_83_78_fe_70_e2_cb_c5_71_41_08_04_71_9e_2c_d1_71_fa_39_48_72_55_2c_84_72_af_05_a6_73_07_c3_cf_73_5f_66_25_73_b5_eb_d0_74_0b_53_fa_74_5f_9d_d0_74_b2_c8_83_75_04_d3_44_75_55_bd_4b_75_a5_85_ce_75_f4_2c_0a_76_41_af_3c_76_8e_0e_a5_76_d9_49_88_77_23_5f_2c_77_6c_4e_da_77_b4_17_df_77_fa_b9_88_78_40_33_28_78_84_84_13_78_c7_ab_a1_79_09_a9_2c_79_4a_7c_11_79_8a_23_b0_79_c8_9f_6d_7a_05_ee_ac_7a_42_10_d8_7a_7d_05_5a_7a_b6_cb_a3_7a_ef_63_23_7b_26_cb_4e_7b_5d_03_9d_7b_92_0b_88_7b_c5_e2_8f_7b_f8_88_2f_7c_29_fb_ed_7c_5a_3d_4f_7c_89_4b_dd_7c_b7_27_23_7c_e3_ce_b1_7d_0f_42_17_7d_39_80_eb_7d_62_8a_c5_7d_8a_5f_3f_7d_b0_fd_f7_7d_d6_66_8e_7d_fa_98_a7_7e_1d_93_e9_7e_3f_57_fe_7e_5f_e4_92_7e_7f_39_56_7e_9d_55_fb_7e_ba_3a_38_7e_d5_e5_c5_7e_f0_58_5f_7f_09_91_c3_7f_21_91_b3_7f_38_57_f5_7f_4d_e4_50_7f_62_36_8e_7f_75_4e_7f_7f_87_2b_f2_7f_97_ce_bc_7f_a7_36_b3_7f_b5_63_b2_7f_c2_55_95_7f_ce_0c_3d_7f_d8_87_8d_7f_e1_c7_6a_7f_e9_cb_bf_7f_f0_94_77_7f_f6_21_81_7f_fa_72_d0_7f_fd_88_59_7f_ff_62_15_7f_ff_ff_ff";

    /**
     * @notice Return the sine of a value, specified in radians scaled by 1e18
     * @dev This algorithm for converting sine only uses integer values, and it works by dividing the
     * circle into 30 bit angles, i.e. there are 1,073,741,824 (2^30) angle units, instead of the
     * standard 360 degrees (2pi radians). From there, we get an output in range -2,147,483,647 to
     * 2,147,483,647, (which is the max value of an int32) which is then converted back to the standard
     * range of -1 to 1, again scaled by 1e18
     * @param _angle Angle to convert
     * @return Result scaled by 1e18
     */
    function sin(uint256 _angle) internal pure returns (int256) {
        unchecked {
            // Convert angle from from arbitrary radian value (range of 0 to 2pi) to the algorithm's range
            // of 0 to 1,073,741,824
            _angle = (ANGLES_IN_CYCLE * (_angle % TWO_PI)) / TWO_PI;

            // Apply a mask on an integer to extract a certain number of bits, where angle is the integer
            // whose bits we want to get, the width is the width of the bits (in bits) we want to extract,
            // and the offset is the offset of the bits (in bits) we want to extract. The result is an
            // integer containing _width bits of _value starting at the offset bit
            uint256 interp = (_angle >> INTERP_OFFSET) &
                ((1 << INTERP_WIDTH) - 1);
            uint256 index = (_angle >> INDEX_OFFSET) & ((1 << INDEX_WIDTH) - 1);

            // The lookup table only contains data for one quadrant (since sin is symmetric around both
            // axes), so here we figure out which quadrant we're in, then we lookup the values in the
            // table then modify values accordingly
            bool is_odd_quadrant = (_angle & QUADRANT_LOW_MASK) == 0;
            bool is_negative_quadrant = (_angle & QUADRANT_HIGH_MASK) != 0;

            if (!is_odd_quadrant) {
                index = SINE_TABLE_SIZE - 1 - index;
            }

            bytes memory table = sin_table;
            // We are looking for two consecutive indices in our lookup table
            // Since EVM is left aligned, to read n bytes of data from idx i, we must read from `i * data_len` + `n`
            // therefore, to read two entries of size entry_bytes `index * entry_bytes` + `entry_bytes * 2`
            uint256 offset1_2 = (index + 2) * entry_bytes;

            // This following snippet will function for any entry_bytes <= 15
            uint256 x1_2;
            assembly {
                // mload will grab one word worth of bytes (32), as that is the minimum size in EVM
                x1_2 := mload(add(table, offset1_2))
            }

            // We now read the last two numbers of size entry_bytes from x1_2
            // in example: entry_bytes = 4; x1_2 = 0x00...12345678abcdefgh
            // therefore: entry_mask = 0xFFFFFFFF

            // 0x00...12345678abcdefgh >> 8*4 = 0x00...12345678
            // 0x00...12345678 & 0xFFFFFFFF = 0x12345678
            uint256 x1 = (x1_2 >> (8 * entry_bytes)) & entry_mask;
            // 0x00...12345678abcdefgh & 0xFFFFFFFF = 0xabcdefgh
            uint256 x2 = x1_2 & entry_mask;

            // Approximate angle by interpolating in the table, accounting for the quadrant
            uint256 approximation = ((x2 - x1) * interp) >> INTERP_WIDTH;
            int256 sine = is_odd_quadrant
                ? int256(x1) + int256(approximation)
                : int256(x2) - int256(approximation);
            if (is_negative_quadrant) {
                sine *= -1;
            }

            // Bring result from the range of -2,147,483,647 through 2,147,483,647 to -1e18 through 1e18.
            // This can never overflow because sine is bounded by the above values
            return (sine * 1e18) / 2_147_483_647;
        }
    }

    /**
     * @notice Return the cosine of a value, specified in radians scaled by 1e18
     * @dev This is identical to the sin() method, and just computes the value by delegating to the
     * sin() method using the identity cos(x) = sin(x + pi/2)
     * @dev Overflow when `angle + PI_OVER_TWO > type(uint256).max` is ok, results are still accurate
     * @param _angle Angle to convert
     * @return Result scaled by 1e18
     */
    function cos(uint256 _angle) internal pure returns (int256) {
        unchecked {
            return sin(_angle + PI_OVER_TWO);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledGenesis.sol";

contract XShackledGenesis {
    constructor() {}

    function xgenerateGenesisPiece(bytes32 tokenHash) external view returns (ShackledStructs.RenderParams memory, ShackledStructs.Metadata memory) {
        return ShackledGenesis.generateGenesisPiece(tokenHash);
    }

    function xgenerateGeometryAndColors(bytes32 tokenHash,int256[3] calldata objPosition) external view returns (ShackledGenesis.FacesVertsCols memory, ColorUtils.ColScheme memory, GeomUtils.GeomSpec memory, GeomUtils.GeomVars memory) {
        return ShackledGenesis.generateGeometryAndColors(tokenHash,objPosition);
    }

    function xcreate2dTris(bytes32 tokenHash,GeomUtils.GeomSpec calldata geomSpec) external view returns (int256[3][3][] memory, int256[] memory, int256[] memory) {
        return ShackledGenesis.create2dTris(tokenHash,geomSpec);
    }

    function xprismify(bytes32 tokenHash,int256[3][3][] calldata tris,int256[] calldata zFronts,int256[] calldata zBacks) external view returns (GeomUtils.GeomVars memory) {
        return ShackledGenesis.prismify(tokenHash,tris,zFronts,zBacks);
    }

    function xmakeFacesVertsCols(bytes32 tokenHash,int256[3][3][] calldata tris,GeomUtils.GeomVars calldata geomVars,ColorUtils.ColScheme calldata scheme,int256[3] calldata objPosition) external view returns (ShackledGenesis.FacesVertsCols memory) {
        return ShackledGenesis.makeFacesVertsCols(tokenHash,tris,geomVars,scheme,objPosition);
    }
}

contract XColorUtils {
    constructor() {}

    function xgetColForPrism(bytes32 tokenHash,int256[3][3] calldata triFront,ColorUtils.SubScheme calldata subScheme,int256[3][2] calldata extents) external view returns (int256[3][6] memory) {
        return ColorUtils.getColForPrism(tokenHash,triFront,subScheme,extents);
    }

    function xgetSchemeId(bytes32 tokenHash,int256[2][10] calldata weightings) external view returns (uint256) {
        return ColorUtils.getSchemeId(tokenHash,weightings);
    }

    function xcopyColor(int256[3] calldata c) external view returns (int256[3] memory) {
        return ColorUtils.copyColor(c);
    }

    function xgetScheme(bytes32 tokenHash,int256[3][3][] calldata tris) external view returns (ColorUtils.ColScheme memory) {
        return ColorUtils.getScheme(tokenHash,tris);
    }

    function xhsv2rgb(int256 h,int256 s,int256 v) external view returns (int256[3] memory) {
        return ColorUtils.hsv2rgb(h,s,v);
    }

    function xrgb2hsv(int256 r,int256 g,int256 b) external view returns (int256[3] memory) {
        return ColorUtils.rgb2hsv(r,g,b);
    }

    function xgetJiggle(int256[3] calldata jiggle,bytes32 randomSeed,int256 seedModifier) external view returns (int256[3] memory) {
        return ColorUtils.getJiggle(jiggle,randomSeed,seedModifier);
    }

    function xinArray(uint256[] calldata array,uint256 value) external view returns (bool) {
        return ColorUtils.inArray(array,value);
    }

    function xapplyDirHelp(int256[3][3] calldata triFront,int256[3] calldata colA,int256[3] calldata colB,int256 dirCode,bool isInnerGradient,int256[3][2] calldata extents) external view returns (int256[3][3] memory) {
        return ColorUtils.applyDirHelp(triFront,colA,colB,dirCode,isInnerGradient,extents);
    }

    function xgetOrderedPointIdxsInDir(int256[3][3] calldata tri,int256 dirCode) external view returns (uint256[3] memory) {
        return ColorUtils.getOrderedPointIdxsInDir(tri,dirCode);
    }

    function xinterpColHelp(int256[3] calldata colA,int256[3] calldata colB,int256 low,int256 high,int256 val) external view returns (int256[3] memory) {
        return ColorUtils.interpColHelp(colA,colB,low,high,val);
    }

    function xgetHighlightPrismIdxs(int256[3][3][] calldata tris,bytes32 tokenHash,uint256 nHighlights,int256 varCode,int256 selCode) external view returns (uint256[] memory) {
        return ColorUtils.getHighlightPrismIdxs(tris,tokenHash,nHighlights,varCode,selCode);
    }

    function xgetSortedTrisIdxs(int256[3][3][] calldata tris,uint256 nHighlights,int256 varCode,int256 selCode) external view returns (uint256[] memory) {
        return ColorUtils.getSortedTrisIdxs(tris,nHighlights,varCode,selCode);
    }
}

contract XGeomUtils {
    constructor() {}

    function xgenerateSpec(bytes32 tokenHash) external view returns (GeomUtils.GeomSpec memory) {
        return GeomUtils.generateSpec(tokenHash);
    }

    function xmakeAdjacentTriangles(bytes32 tokenHash,uint256 attemptNum,uint256 refIdx,GeomUtils.TriVars calldata triVars,GeomUtils.GeomSpec calldata geomSpec,int256 overrideSideIdx,int256 overrideScale,int256 depth) external view returns (GeomUtils.TriVars memory) {
        return GeomUtils.makeAdjacentTriangles(tokenHash,attemptNum,refIdx,triVars,geomSpec,overrideSideIdx,overrideScale,depth);
    }

    function xmakeVerticallyOppositeTriangles(bytes32 tokenHash,uint256 attemptNum,uint256 refIdx,GeomUtils.TriVars calldata triVars,GeomUtils.GeomSpec calldata geomSpec,int256 overrideSideIdx,int256 overrideScale,int256 depth) external view returns (GeomUtils.TriVars memory) {
        return GeomUtils.makeVerticallyOppositeTriangles(tokenHash,attemptNum,refIdx,triVars,geomSpec,overrideSideIdx,overrideScale,depth);
    }

    function xmakeTriVertOpp(int256[3][3] calldata refTri,GeomUtils.GeomSpec calldata geomSpec,int256 sideIdx,int256 scale) external view returns (int256[3][3] memory) {
        return GeomUtils.makeTriVertOpp(refTri,geomSpec,sideIdx,scale);
    }

    function xmakeTriAdjacent(bytes32 tokenHash,GeomUtils.GeomSpec calldata geomSpec,uint256 attemptNum,int256[3][3] calldata refTri,int256 sideIdx,int256 scale,int256 depth) external view returns (int256[3][3] memory) {
        return GeomUtils.makeTriAdjacent(tokenHash,geomSpec,attemptNum,refTri,sideIdx,scale,depth);
    }

    function xmakeTri(int256[3] calldata centre,int256 radius,int256 angle) external view returns (int256[3][3] memory) {
        return GeomUtils.makeTri(centre,radius,angle);
    }

    function xvector3RotateX(int256[3] calldata v,int256 deg) external view returns (int256[3] memory) {
        return GeomUtils.vector3RotateX(v,deg);
    }

    function xvector3RotateY(int256[3] calldata v,int256 deg) external view returns (int256[3] memory) {
        return GeomUtils.vector3RotateY(v,deg);
    }

    function xvector3RotateZ(int256[3] calldata v,int256 deg) external view returns (int256[3] memory) {
        return GeomUtils.vector3RotateZ(v,deg);
    }

    function xtrigHelper(int256 deg) external view returns (int256, int256) {
        return GeomUtils.trigHelper(deg);
    }

    function xgetCenterVec(int256[3][3] calldata tri) external view returns (int256[3] memory) {
        return GeomUtils.getCenterVec(tri);
    }

    function xgetRadiusLen(int256[3][3] calldata tri) external view returns (int256) {
        return GeomUtils.getRadiusLen(tri);
    }

    function xgetSideLen(int256[3][3] calldata tri) external view returns (int256) {
        return GeomUtils.getSideLen(tri);
    }

    function xgetPerpLen(int256[3][3] calldata tri) external view returns (int256) {
        return GeomUtils.getPerpLen(tri);
    }

    function xisTriPointingUp(int256[3][3] calldata tri) external view returns (bool) {
        return GeomUtils.isTriPointingUp(tri);
    }

    function xareTrisClose(int256[3][3] calldata tri1,int256[3][3] calldata tri2) external view returns (bool) {
        return GeomUtils.areTrisClose(tri1,tri2);
    }

    function xareTrisPointsOverlapping(int256[3][3] calldata tri1,int256[3][3] calldata tri2) external view returns (bool) {
        return GeomUtils.areTrisPointsOverlapping(tri1,tri2);
    }

    function xisPointInTri(int256[3][3] calldata tri,int256[3] calldata p) external view returns (bool) {
        return GeomUtils.isPointInTri(tri,p);
    }

    function xisTriOverlappingWithTris(int256[3][3] calldata tri,int256[3][3][] calldata tris,uint256 nextTriIdx) external view returns (bool) {
        return GeomUtils.isTriOverlappingWithTris(tri,tris,nextTriIdx);
    }

    function xisPointCloseToLine(int256[3] calldata p,int256[3] calldata l1,int256[3] calldata l2) external view returns (bool) {
        return GeomUtils.isPointCloseToLine(p,l1,l2);
    }

    function xisTrisPointsCloseToLines(int256[3][3] calldata tri,int256[3][3][] calldata tris,uint256 nextTriIdx) external view returns (bool) {
        return GeomUtils.isTrisPointsCloseToLines(tri,tris,nextTriIdx);
    }

    function xisTriLegal(int256[3][3] calldata tri,int256[3][3][] calldata tris,uint256 nextTriIdx,int256 minTriRad) external view returns (bool) {
        return GeomUtils.isTriLegal(tri,tris,nextTriIdx,minTriRad);
    }

    function xattemptToAddTri(int256[3][3] calldata tri,bytes32 tokenHash,GeomUtils.TriVars calldata triVars,GeomUtils.GeomSpec calldata geomSpec) external view returns (bool) {
        return GeomUtils.attemptToAddTri(tri,tokenHash,triVars,geomSpec);
    }

    function xtriRotHelp(int256 axis,int256[3][3] calldata tri,int256 rot) external view returns (int256[3][3] memory) {
        return GeomUtils.triRotHelp(axis,tri,rot);
    }

    function xtriBfHelp(int256 axis,int256[3][3][] calldata trisBack,int256[3][3][] calldata trisFront,int256 rot) external view returns (int256[3][3][] memory, int256[3][3][] memory) {
        return GeomUtils.triBfHelp(axis,trisBack,trisFront,rot);
    }

    function xgetExtents(int256[3][3][] calldata tris) external view returns (int256[3][2] memory) {
        return GeomUtils.getExtents(tris);
    }

    function xcalculateZ(int256[3][3] calldata tri,bytes32 tokenHash,uint256 nextTriIdx,GeomUtils.GeomSpec calldata geomSpec,bool front) external view returns (int256) {
        return GeomUtils.calculateZ(tri,tokenHash,nextTriIdx,geomSpec,front);
    }

    function xgetSpecId(bytes32 tokenHash,int256[2][7] calldata weightings) external view returns (uint256) {
        return GeomUtils.getSpecId(tokenHash,weightings);
    }

    function xrandN(bytes32 randomSeed,string calldata seedModifier,int256 min,int256 max) external view returns (int256) {
        return GeomUtils.randN(randomSeed,seedModifier,min,max);
    }

    function xclipTrisToLength(int256[3][3][] calldata arr,uint256 desiredLen) external view returns (int256[3][3][] memory) {
        return GeomUtils.clipTrisToLength(arr,desiredLen);
    }

    function xclipZsToLength(int256[] calldata arr,uint256 desiredLen) external view returns (int256[] memory) {
        return GeomUtils.clipZsToLength(arr,desiredLen);
    }

    function xcopyTri(int256[3][3] calldata tri) external view returns (int256[3][3] memory) {
        return GeomUtils.copyTri(tri);
    }

    function xcopyTris(int256[3][3][] calldata tris) external view returns (int256[3][3][] memory) {
        return GeomUtils.copyTris(tris);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledMath.sol";

contract XShackledMath {
    constructor() {}

    function xmin(int256 a,int256 b) external pure returns (int256) {
        return ShackledMath.min(a,b);
    }

    function xmax(int256 a,int256 b) external pure returns (int256) {
        return ShackledMath.max(a,b);
    }

    function xmod(int256 n,int256 m) external pure returns (int256) {
        return ShackledMath.mod(n,m);
    }

    function xrandomIdx(bytes32 seedModifier,uint256 n,uint256 m) external pure returns (uint256[] memory) {
        return ShackledMath.randomIdx(seedModifier,n,m);
    }

    function xget2dArray(uint256 m,uint256 q,int256 value) external pure returns (int256[][] memory) {
        return ShackledMath.get2dArray(m,q,value);
    }

    function xabs(int256 x) external pure returns (int256) {
        return ShackledMath.abs(x);
    }

    function xsqrt(int256 y) external pure returns (int256) {
        return ShackledMath.sqrt(y);
    }

    function xhypot(int256 x,int256 y) external pure returns (int256) {
        return ShackledMath.hypot(x,y);
    }

    function xvector3Add(int256[3] calldata v1,int256[3] calldata v2) external pure returns (int256[3] memory) {
        return ShackledMath.vector3Add(v1,v2);
    }

    function xvector3Sub(int256[3] calldata v1,int256[3] calldata v2) external pure returns (int256[3] memory) {
        return ShackledMath.vector3Sub(v1,v2);
    }

    function xvector3MulScalar(int256[3] calldata v,int256 a) external pure returns (int256[3] memory) {
        return ShackledMath.vector3MulScalar(v,a);
    }

    function xvector3DivScalar(int256[3] calldata v,int256 a) external pure returns (int256[3] memory) {
        return ShackledMath.vector3DivScalar(v,a);
    }

    function xvector3Len(int256[3] calldata v) external pure returns (int256) {
        return ShackledMath.vector3Len(v);
    }

    function xvector3NormX(int256[3] calldata v,int256 fidelity) external pure returns (int256[3] memory) {
        return ShackledMath.vector3NormX(v,fidelity);
    }

    function xvector3Dot(int256[3] calldata v1,int256[3] calldata v2) external view returns (int256) {
        return ShackledMath.vector3Dot(v1,v2);
    }

    function xcrossProduct(int256[3] calldata v1,int256[3] calldata v2) external pure returns (int256[3] memory) {
        return ShackledMath.crossProduct(v1,v2);
    }

    function xvector12Lerp(int256[12] calldata v1,int256[12] calldata v2,int256 ir,int256 scaleFactor) external view returns (int256[12] memory) {
        return ShackledMath.vector12Lerp(v1,v2,ir,scaleFactor);
    }

    function xvector12Sub(int256[12] calldata v1,int256[12] calldata v2) external view returns (int256[12] memory) {
        return ShackledMath.vector12Sub(v1,v2);
    }

    function xmapRangeToRange(int256 num,int256 inMin,int256 inMax,int256 outMin,int256 outMax) external pure returns (int256) {
        return ShackledMath.mapRangeToRange(num,inMin,inMax,outMin,outMax);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/ShackledStructs.sol";

contract XShackledStructs {
    constructor() {}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/Trigonometry.sol";

contract XTrigonometry {
    constructor() {}

    function xsin(uint256 _angle) external pure returns (int256) {
        return Trigonometry.sin(_angle);
    }

    function xcos(uint256 _angle) external pure returns (int256) {
        return Trigonometry.cos(_angle);
    }
}