import re
import numpy as np
import os
from collections import defaultdict

def celltracer_initialize_parameters():
    """
    Initialize the parameters for cell tracing.
    Returns two dictionaries: ip for image parameters and op for operation parameters.
    """

    # Image parameters
    ip = {
        'fname': None,
        'sname': None,
        'indsz': {'xy': None, 'z': None, 't': None, 'c': None},
        'flipxyt': False,
        'bkg': {'reg': None, 'fix': None, 'dyn': None, 'altxy': None, 'bkonly': None},
        'xyshift': {'frame': None, 'dx': None, 'dy': None,
                    'trackwell': None, 'trackchan': None, 'badtime': None,
                    'shifttype': 'translation'},
        'bkmd': None,
        'bval': None
    }

    # Operation parameters
    op = {
        'cname': None,
        'cind': None,
        'xypos': None,
        'trng': None,
        'nW': None,
        'objbias': None,
        'unmix': None,
        'fixshift': None,
        'mdover': None,
        'seg': {'chan': None, 'cyt': False, 'maxD': None, 'minD': None,
                'maxEcc': None, 'Extent': None},
        'msk': {'fret': None, 'freti': None, 'rt': [], 'storemasks': False,
                'saverawvals': False, 'aggfun': None},
        'trk': {'nnwin': None, 'gapwin': None},
        'par': {'minPW': 5, 'nIter': 3},
        'disp': {'meta': False, 'samples': False, 'shifts': False, 'warnings': False},
        'pth': None
    }

    return ip, op

#Initialize
ip, op = celltracer_initialize_parameters()

# Imaging Parameters
# ------------------

# Data locations:
fpath = './'  # Assumes it is in current folder
fname = '20180123 MCF10 EKAR Fra T4 ratio expt downstairs.nd2'
ip = {}

# Assemble complete path for data file
dd = os.path.join(fpath, fname)
ip['fname'] = dd

spath = '../Processed Data/'  # Assumes a parallel folder
sname = '20180123_Downstairs'
# Assemble complete path for save file
dd = os.path.join(spath, sname)
ip['sname'] = dd

# Data - basic statistics
ip['indsz'] = {'xy': [61], 'z': [1], 't': [228], 'c': [4]}
ip['tsamp'] = [7]

# Data - detailed definitions
ip['bval'] = 100
ip['bkg'] = [{'reg': [], 'fix': False, 'dyn': True, 'altxy': 61, 'bkonly': False} for _ in range(61)]
ip['bkg'][60]['bkonly'] = True
ip['bkg'][60]['reg'] = [[788, 25], [948, 161]]
ip['bkg'][60]['altxy'] = 0

ip['xyshift'] = {
    'frame': [], 'dx': [], 'dy': [], 'trackwell': [], 
    'trackchan': [], 'badtime': [], 'shifttype': 'translation'
}

# Backup imaging MetaData
ip['bkmd'] = {
    'obj': {
        'Desc': 'Apo_20x', 'Mag': 20, 'WkDist': 1, 
        'RefIndex': 1, 'NA': 0.75
    },
    'cam': {
        'Desc': 'Zyla5', 'PixSizeX': 0.65, 'PixSizeY': 0.65,
        'PixNumX': 1280, 'PixNumY': 1080, 'BinSizeX': 2, 'BinSizeY': 2
    },
    'exp': {
        'Channel': ['DAPI', 'EKAR_CFP', 'EKAR_YFP', 'Fra1_RFP'],
        'Filter': ['Filter_DAPI', 'Filter_CFP', 'Filter_YFP', 'Filter_Cherry2'],
        'FPhore': ['DAPI', 'CFP', 'YFP', 'RFP'],
        'FRET': [],
        'Light': 'SOLA',
        'Exposure': [100, 150, 100, 500],
        'ExVolt': [10, 14, 15, 40]
    }
}

# Operation Parameters
# --------------------

op = {}

op['cind'] = list(range(1, 5))
op['xypos'] = list(range(1, 62))
op['trng'] = list(range(1, 229))
op['nW'] = 10
op['flatten'] = False
op['objbias'] = True
op['unmix'] = False
op['fixshift'] = False

op['mdover'] = [['exp', 'ExVolt'], ['exp', 'Exposure'], ['exp', 'Filter'], ['exp', 'Channel'], ['exp', 'FPhore']]

# Procedure settings
op['seg'] = {
    'chan': [4], 'cyt': False, 'maxD': 35, 'minD': 9, 
    'maxEcc': 0.9, 'Extent': [0.65, 0.85], 'sigthresh': [], 'hardsnr': False
}
op['msk'] = {
    'rt': [], 'storemasks': False, 'saverawvals': True, 'aggfun': []
}
op['trk'] = {'movrad': 25, 'linkwin': 75}
op['disp'] = {'meta': False, 'samples': False, 'shifts': False, 'warnings': True}

# Do NOT edit the following parameter transfers
op['cname'] = ip['bkmd']['exp']['Channel']
op['msk']['fret'] = ip['bkmd']['exp']['FRET']

# Assuming op.objbias and other values are predefined elsewhere

# Objective Metadata
mdi = {
    "obj": {
        "Desc": [ip['bkmd']['obj']['Desc']],
        "NA": [ip['bkmd']['obj']['NA']],
        "Mag": [ip['bkmd']['obj']['Mag']],
        "WkDist": [ip['bkmd']['obj']['WkDist']],
        "RefIndex": [ip['bkmd']['obj']['RefIndex']]
    },
    
    # Camera Metadata
    "cam": {
        "Desc": [ip['bkmd']['cam']['Desc']],
        "PixSizeX": [ip['bkmd']['cam']['PixSizeX']],
        "PixSizeY": [ip['bkmd']['cam']['PixSizeY']],
        "PixNumX": [ip['bkmd']['cam']['PixNumX']],
        "PixNumY": [ip['bkmd']['cam']['PixNumY']],
        "BinSizeX": [ip['bkmd']['cam']['BinSizeX']],
        "BinSizeY": [ip['bkmd']['cam']['BinSizeY']],
        "tsamp": [7]
    },

    # Experiment Metadata (initially setting just Light and MultiLaser)
    "exp": {
        "Light": ['SPECTRAX'],
        "MultiLaser": [],
        'Channel': ['DAPI', 'EKAR_CFP', 'EKAR_YFP', 'Fra1_RFP'],
        'Filter': ['Filter_DAPI', 'Filter_CFP', 'Filter_YFP', 'Filter_Cherry2'],
        'FPhore': ['DAPI', 'CFP', 'YFP', 'RFP'],
        'FRET': [],
        'Exposure': [100, 150, 100, 500],
        'ExVolt': [10, 14, 15, 40],
        'ExWL' : [395,440,508,550],
        'ExLine' : [1,2,4,5],
        "GainMode" : ['Dual Gain 1/4']
    }
}

