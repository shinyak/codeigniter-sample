<?php

namespace App\Controllers;

use CodeIgniter\HTTP\ResponseInterface;
use Config\Database;

class DbHealth extends BaseController
{
    public function index(): ResponseInterface
    {
        $db = Database::connect();
        $tables = array_map('current', $db->query('SHOW TABLES')->getResultArray());

        return $this->response->setJSON([
            'database'  => $db->getDatabase(),
            'tables'    => $tables,
            'timestamp' => date(DATE_ATOM),
        ]);
    }
}
