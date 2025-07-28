import os
from dotenv import load_dotenv
import xmlrpc.client

load_dotenv()

class OdooService:
    def __init__(self):
        self.url = os.getenv("ODOO_URL")
        self.db = os.getenv("ODOO_DB")
        self.username = os.getenv("ODOO_USER")
        self.password = os.getenv("ODOO_PASSWORD")
        self.common = xmlrpc.client.ServerProxy(f"{self.url}/xmlrpc/2/common")
        self.uid = self.common.authenticate(self.db, self.username, self.password, {})
        self.models = xmlrpc.client.ServerProxy(f"{self.url}/xmlrpc/2/object")

    def search(self, model, domain=None, limit=10):
        domain = domain or []
        return self.models.execute_kw(
            self.db, self.uid, self.password,
            model, 'search',
            [domain], {'limit': limit}
        )

    def read(self, model, ids, fields=None):
        return self.models.execute_kw(
            self.db, self.uid, self.password,
            model, 'read',
            [ids], {'fields': fields or []}
        )

    def create(self, model, data):
        return self.models.execute_kw(
            self.db, self.uid, self.password,
            model, 'create',
            [data]
        )

    def update(self, model, ids, data):
        return self.models.execute_kw(
            self.db, self.uid, self.password,
            model, 'write',
            [ids, data]
        )

    def delete(self, model, ids):
        return self.models.execute_kw(
            self.db, self.uid, self.password,
            model, 'unlink',
            [ids]
        )

    def search_account_moves(self, domain=None, limit=10):
        """
        Récupère les IDs des écritures comptables (account.move).
        :param domain: liste de filtres Odoo (ex: [['state', '=', 'posted']])
        :param limit: nombre maximum de résultats
        :return: liste d'IDs
        """
        domain = domain or []
        return self.models.execute_kw(
            self.db, self.uid, self.password,
            'account.move', 'search',
            [domain], {'limit': limit}
        )

    def read_account_moves(self, ids, fields=None):
        """
        Lit les écritures comptables (account.move) pour les IDs donnés.
        :param ids: liste d'IDs
        :param fields: liste des champs à lire (ex: ['name', 'date', 'state'])
        :return: liste de dictionnaires
        """
        return self.models.execute_kw(
            self.db, self.uid, self.password,
            'account.move', 'read',
            [ids], {'fields': fields or []}
        )

    def search_account_move_lines(self, domain=None, limit=10):
        """
        Récupère les IDs des lignes d'écriture comptable (account.move.line).
        :param domain: liste de filtres Odoo
        :param limit: nombre maximum de résultats
        :return: liste d'IDs
        """
        domain = domain or []
        return self.models.execute_kw(
            self.db, self.uid, self.password,
            'account.move.line', 'search',
            [domain], {'limit': limit}
        )

    def read_account_move_lines(self, ids, fields=None):
        """
        Lit les lignes d'écriture comptable (account.move.line) pour les IDs donnés.
        :param ids: liste d'IDs
        :param fields: liste des champs à lire
        :return: liste de dictionnaires
        """
        return self.models.execute_kw(
            self.db, self.uid, self.password,
            'account.move.line', 'read',
            [ids], {'fields': fields or []}
        )

    def search_read(self, model, domain=None, fields=None, limit=1000):
        domain = domain or []
        fields = fields or []
        return self.models.execute_kw(
            self.db, self.uid, self.password,
            model, 'search_read',
            [domain],
            {'fields': fields, 'limit': limit}
        )

if __name__ == "__main__":
    odoo = OdooService()

    move_ids = odoo.search_account_moves(domain=[['state', '=', 'posted']], limit=10)
    moves = odoo.read_account_moves(move_ids, fields=['name', 'date', 'journal_id', 'state'])
    print("Écritures comptables :", moves)

    if move_ids:
        line_ids = odoo.search_account_move_lines(domain=[['move_id', '=', move_ids[0]]], limit=20)
        lines = odoo.read_account_move_lines(line_ids, fields=['date', 'account_id', 'partner_id', 'debit', 'credit', 'name'])
        print("Lignes de l'écriture :", lines)
