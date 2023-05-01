import {  expect } from "chai";
import {  ethers } from "hardhat";
import { BigNumber } from "ethers";

describe("Test 721WG0", function () {
    let owner, userA, userB;
    let kittyCoreTest, wG0Test, wG0NFT;

    beforeEach(async function () {
        [owner,userA, userB] = await ethers.getSigners();
        const KittyCoreTest = await ethers.getContractFactory("KittyCoreTest");
        const WG0Test = await ethers.getContractFactory("WG0Test");
        const WG0NFT = await ethers.getContractFactory("WrappedGen0CryptoKitties");

        kittyCoreTest = await KittyCoreTest.deploy();
        wG0Test = await WG0Test.deploy(kittyCoreTest.address);
        wG0NFT = await WG0NFT.deploy(kittyCoreTest.address, wG0Test.address);
    })

    describe("wrap & unwrap ", function () {
        it("wrap &  unwrap", async function () {
            const id =  3001;
            const gen = 0;
            await kittyCoreTest.mintGreaterThan3000(id, gen);
            expect(await kittyCoreTest.ownerOf(id)).equal(owner.address);
    
            await kittyCoreTest.approve(wG0NFT.address, id);

            await wG0NFT.wrap(id);

            expect(await wG0NFT.ownerOf(id)).equal(owner.address);
            expect(await kittyCoreTest.ownerOf(id)).equal(wG0NFT.address);

            await wG0NFT.unwrap(id);
            expect(await kittyCoreTest.ownerOf(id)).equal(owner.address);

        });
        
        it("fail if the NFT is not Gen0", async function () {
            const id =  3002;
            const gen = 1;

            await kittyCoreTest.mintGreaterThan3000(id, gen);
            expect(await kittyCoreTest.ownerOf(id)).equal(owner.address);
    
            await kittyCoreTest.approve(wG0NFT.address, id);

            await expect(wG0NFT.wrap(id)).to.be.revertedWith("kitty must be Gen0");
        });
    });

    describe("swap between WG0 and 721WG0", function () {

        it("swapFromWG0ToNft & swapFromNftToWG0", async function () {
            const id1 = 3001;
            const id2 = 3002;
            const gen = 0;
            await kittyCoreTest.mintGreaterThan3000(id1, gen);
            await kittyCoreTest.approve(wG0Test.address, id1);

            await kittyCoreTest.mintGreaterThan3000(id2, gen);
            await kittyCoreTest.approve(wG0Test.address, id2);

            await wG0Test.depositKittiesAndMintTokens([id1, id2]);

            expect(await kittyCoreTest.ownerOf(id1)).equal(wG0Test.address);
            expect(await kittyCoreTest.ownerOf(id2)).equal(wG0Test.address);

            await wG0Test.approve(wG0NFT.address, ethers.utils.parseEther('2'));
            await wG0NFT.swapFromWG0ToNft([id1,id2], owner.address);
            expect(await wG0NFT.ownerOf(id1)).equal(owner.address);
            expect(await wG0NFT.ownerOf(id2)).equal(owner.address);
            expect(await kittyCoreTest.ownerOf(id1)).equal(wG0NFT.address);
            expect(await kittyCoreTest.ownerOf(id2)).equal(wG0NFT.address);

            await wG0NFT.swapFromNftToWG0([id1,id2], owner.address);
            expect(await kittyCoreTest.ownerOf(id1)).equal(wG0Test.address);
            expect(await kittyCoreTest.ownerOf(id2)).equal(wG0Test.address);

        });

        it("invalid count", async function () {
            await expect(wG0NFT.swapFromWG0ToNft([],owner.address)).to.be.revertedWith("invalid count");
            await expect(wG0NFT.swapFromNftToWG0([],owner.address)).to.be.revertedWith("invalid count");
        });

        it("not owner", async function () {

            const id =  3001;
            const gen = 0;
            await kittyCoreTest.mintGreaterThan3000(id, gen);
            expect(await kittyCoreTest.ownerOf(id)).equal(owner.address);
    
            await kittyCoreTest.approve(wG0NFT.address, id);

            await wG0NFT.wrap(id);

            await expect(wG0NFT.connect(userA).swapFromNftToWG0([id],owner.address)).to.be.revertedWith("not owner");
        });
        
    });
});

