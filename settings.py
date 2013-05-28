import os

class Config(dict):
    """ This class subclasses dict, retrieving the environment variable
        first if it exists, otherwise get the default config value
    """

    def __init__(self, *args, **kwargs):
        self.update(*args, **kwargs)
        # Load default settings
        execfile("default_settings.py", self)

    def __getitem__(self, key):
        value = os.getenv(key)
        if value == None:
            return dict.__getitem__(self, key)
        return Config.convert_vars(value)

    def __setitem__(self, key, val):
        dict.__setitem__(self, key, val)

    def __repr__(self):
        dictrepr = dict.__repr__(self)
        return '%s(%s)' % (type(self).__name__, dictrepr)

    def update(self, *args, **kwargs):
        for k, v in dict(*args, **kwargs).iteritems():
            self[k] = v

    @staticmethod
    def convert_vars(s):
        if s in ['True', 'true', 'TRUE', '1', 'y', 'yes', 'Yes', 'YES']:
            return True
        if s in ['False', 'false', 'FALSE', '0', 'n', 'no', 'No', 'NO']:
            return False
        if s.isdigit():
            return int(s)
        return s