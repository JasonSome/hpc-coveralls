{-# LANGUAGE CPP #-}

-- |
-- Module:      Trace.Hpc.Coveralls.Cabal
-- Copyright:   (c) 2014-2015 Guillaume Nargeot
-- License:     BSD3
-- Maintainer:  Guillaume Nargeot <guillaume+hackage@nargeot.com>
-- Stability:   experimental
--
-- Functions for reading cabal package name and version.

module Trace.Hpc.Coveralls.Cabal (currDirPkgNameVer, getPackageNameVersion) where

import Control.Applicative
import Control.Monad
import Control.Monad.Trans.Maybe
import Data.List (intercalate, isSuffixOf)
import Distribution.Package
import Distribution.PackageDescription
import Distribution.PackageDescription.Parsec
import qualified Data.ByteString as BS
import Distribution.Version
import System.Directory

getCabalFile :: FilePath -> IO (Maybe FilePath)
getCabalFile dir = do
    files <- (filter isCabal <$> getDirectoryContents dir) >>= filterM doesFileExist
    case files of
        [file] -> return $ Just file
        _ -> return Nothing
    where isCabal filename = ".cabal" `isSuffixOf` filename && length filename > 6

getPackageNameVersion :: FilePath -> IO (Maybe String)
getPackageNameVersion file = do
    orig <- BS.readFile file
    case parseGenericPackageDescriptionMaybe orig of
        Nothing  -> return Nothing
        Just gpd -> return $ Just $ name ++ "-" ++ version
            where pkg = package . packageDescription $ gpd
                  name = unPackageName $ pkgName pkg
                  version = showVersion (pkgVersion pkg)
                  showVersion = intercalate "." . map show . versionNumbers

currDirPkgNameVer :: IO (Maybe String)
currDirPkgNameVer = runMaybeT $ pkgNameVersion currentDir
    where pkgNameVersion = MaybeT . getPackageNameVersion <=< MaybeT . getCabalFile
          currentDir = "."

#if !(MIN_VERSION_Cabal(1,22,0))
unPackageName :: PackageName -> String
unPackageName (PackageName name) = name
#endif

#if !(MIN_VERSION_Cabal(2,0,0))
versionNumbers :: Version -> [Int]
versionNumbers = versionBranch
#endif
